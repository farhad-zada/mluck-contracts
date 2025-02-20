// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Staking {
  address staker;
  uint256 amount;
  uint256 stakedAt;
  uint256 claimedAt;
  uint256 lastClaimedDailyStatIdx;
  bool unstaked;
}

struct DailyStat {
  uint256 date;
  uint256 amount;
  uint256 daysStayed;
  uint256 dayUsdtShare;
}

struct Revenue {
  uint256 date;
  uint256 amount;
  uint256 lastDailyStatIdx;
}

enum Status {
  OPEN,
  CLOSE,
  PAUSED,
  ENDED
}

contract StakingMLUCKForUSDT {
  IERC20 public mluckToken;
  IERC20 public usdtToken;

  uint256 public minStakePerWallet;
  uint256 public maxStakePerWallet;
  uint256 public poolSize;
  uint256 public totalStaked;
  uint256 public penaltyPercent;
  Status public status;

  uint256 public DAILYSTAT_CYCLE_PERIOD = 1 days; // TODO: update as needed
  uint256 public REVENUE_CYCLE_PERIOD = 30 days; // TODO: update as needed
  uint256 public STAKE_LOCK_PERIOD = 7 days; // TODO: update as needed

  DailyStat[] public dailyStats;
  Revenue[] public revenues;
  /**
   * @dev Mapping of a stake's info to the staker's address
   * I use mapping instead of array to make it safe and also it is more
   * relevant to our use case.
   */
  mapping(address => Staking[]) public stakings;
  mapping(address => uint256) public walletStakingsTotal;
  event Stake(address indexed staker, uint256 amount, uint256 timestamp);
  event AddRevenue(uint256 amount, uint256 timestamp);

  modifier canStake(uint256 amount) {
    require(amount > 0, "mluck_for_usdt: cannot stake 0");
    require(amount >= minStakePerWallet, "mluck_for_usdt: low amount");
    require(amount + walletStakingsTotal[msg.sender] <= maxStakePerWallet, "mluck_for_usdt: high amount");
    require(amount + totalStaked < poolSize, "mluck_for_usdt: pool is full");
    require(status == Status.OPEN, "mluck_for_usdt: status is not open");
    _;
  }

  modifier canClaim(address msgSender, uint256 id) {
    require(id < stakings[msgSender].length, "mluck_for_usdt: invalid stake id");
    require(!stakings[msgSender][id].unstaked, "mluck_for_usdt: stake is already unstaked");
    _;
  }

  modifier canUnstake(uint256 id) {
    require(id < stakings[msg.sender].length, "mluck_for_usdt: invalid stake id");
    require(block.timestamp - stakings[msg.sender][id].stakedAt > STAKE_LOCK_PERIOD, "mluck_for_usdt: in lock period");
    _;
  }

  constructor(address _mluckToken, address _usdtToken) {
    mluckToken = IERC20(_mluckToken);
    usdtToken = IERC20(_usdtToken);
    poolSize = mluckToken.totalSupply();
    minStakePerWallet = 0;
    maxStakePerWallet = mluckToken.totalSupply();
    status = Status.OPEN;
  }

  function stake(uint256 amount) public canStake(amount) {
    walletStakingsTotal[msg.sender] += amount;
    totalStaked += amount;
    stakings[msg.sender].push(
      Staking(msg.sender, amount, block.timestamp, block.timestamp, dailyStats.length - 1, false)
    );
    updateDailyStats(amount);
    emit Stake(msg.sender, amount, block.timestamp);
  }

  /**
   * @dev Claim the reward for the staker's stake by the given id
   * @param id the id of the stake to claim the reward for
   */
  function claimReward(uint256 id) public view canClaim(msg.sender, id) {
    Staking memory staking = stakings[msg.sender][id];
    uint256 reward = calculateReward(id);
    reward++;
    staking.amount += 0;
    // TODO: implement reward transfer logic
  }

  function unstake(uint256 id) public canUnstake(id) {
    // TODO: implement
    Staking memory staking = stakings[msg.sender][id];
    walletStakingsTotal[msg.sender] -= staking.amount;
    totalStaked -= staking.amount;
    stakings[msg.sender][id].unstaked = true;
    // mluckToken.transfer(staking.staker, staking.amount);
  }

  function addRevenue(uint256 amount) public {
    // Check token allowed
    // usdtToken.transferFrom(msg.sender, address(this), amount); // TODO: do we need this check? // TODO: check if it fails
    require(usdtToken.transferFrom(msg.sender, address(this), amount), "mluck: failed transfer from");
    Revenue memory revenue = Revenue({ date: 0, amount: amount, lastDailyStatIdx: 0 });
    if (revenues.length == 0) {
      revenue.date = (block.timestamp / DAILYSTAT_CYCLE_PERIOD) * DAILYSTAT_CYCLE_PERIOD;
      dailyStats.push(
        DailyStat({ date: revenue.date, amount: 0, daysStayed: 0, dayUsdtShare: amount / REVENUE_CYCLE_PERIOD })
      );
    } else {
      revenue.date = revenues[revenues.length - 1].date + REVENUE_CYCLE_PERIOD;
    }
    revenues.push(revenue);
  }

  function calculatePenalty(uint256 id) public view returns (uint256) {
    Staking memory staking = stakings[msg.sender][id];
    return (staking.amount * penaltyPercent) / 100;
  }

  /**
   * @dev Calculates the reward for the staker's given stake
   * @param id the stake struct to calculate the reward for
   */
  function calculateReward(uint256 id) public view returns (uint256 reward) {
    Staking memory staking = stakings[msg.sender][id];
    // calculate incomplete daily stat reward
    DailyStat memory dailyStatLatest = dailyStats[staking.lastClaimedDailyStatIdx];
    if (staking.claimedAt < dailyStatLatest.date + dailyStatLatest.daysStayed * DAILYSTAT_CYCLE_PERIOD) {
      uint256 rewardingUnits = (staking.claimedAt - dailyStatLatest.date) / DAILYSTAT_CYCLE_PERIOD;
      reward += (rewardingUnits * dailyStatLatest.dayUsdtShare) / dailyStatLatest.amount;
    }
    for (uint256 i = staking.lastClaimedDailyStatIdx + 1; i < dailyStats.length; i++) {
      DailyStat memory dailyStat = dailyStats[i];
      reward += (staking.amount * dailyStat.dayUsdtShare) / dailyStat.amount;
    }
  }

  function updateDailyStats(uint256 amount) public {
    uint256 blockDay = (block.timestamp / DAILYSTAT_CYCLE_PERIOD) * DAILYSTAT_CYCLE_PERIOD;
    uint256 idx = dailyStats.length - 1;
    if (dailyStats[idx].date == blockDay) {
      dailyStats[idx].amount += amount;
      return;
    }
    dailyStats.push(DailyStat({ date: blockDay, amount: amount, daysStayed: 0, dayUsdtShare: 0 }));
    dailyStats[idx].daysStayed = (blockDay - dailyStats[idx].date) / DAILYSTAT_CYCLE_PERIOD;
  }
}
