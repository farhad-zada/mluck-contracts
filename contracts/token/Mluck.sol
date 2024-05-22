// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ValidateRequest} from "../utils/ValidateRequest.sol";
import {RequestType} from "../utils/enums/RequestType.sol";
import {Request} from "../utils/structs/Request.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Mluck
 * @dev ERC20 token with special features:
 * - Remnant MLK in sender's account can't be transferred or spent
 * - Governors can be added/removed by other governors
 * - Owner can withdraw ETH or ERC20 tokens
 * - Governors can request to mint, withdraw, manage governors, set approve threshold, and set remnant
 * @notice Initial supply: 100,000,000 MLKa
 * @notice Max supply: 1,000,000,000 MLK
 * @notice Remnant MLK cannot be transferred or spent
 */

contract Mluck is Ownable, ERC20, ValidateRequest, ReentrancyGuard {
    /// @dev The maximum supply of the MLK token
    /// @notice The maximum supply of the MLK token is 1000,000,000 MLK
    uint256 public constant MAX_SUPPLY = 100_000_000_000 ether;

    /// @dev The amount of MLK that should remain in the sender's account that can't be transferred or spent
    uint256 private s_remnant;

    /// @dev The threshold of approvals needed for a request to be executed
    uint256 private s_approveThreshold;

    /// @dev The list of governors that can make requests and approve them
    address[] private s_governors;

    /// @dev The list of requests made by the governors to mint, withdraw, add or remove governors,
    /// set the approve threshold, set the remnant
    Request[] private s_requests;

    /// @dev The mapping of requests that have been voted by the governors
    mapping(bytes32 => mapping(address => bool)) private s_voted;

    /// @dev Emitted when a governor makes a request
    /// @param  requestType The type of request
    /// @param id The id of the request
    event MadeRequest(RequestType requestType, bytes data, bytes32 id);

    /// @dev Emitted when withdraw is approved and executed.
    event Withdraw(address indexed to, uint256 amount);

    ///@dev Emitted when the remnant amount of MLK is set by approvment. this is implemented by multi approve and executed by the majority of the governors
    ///@param amount The amount of MLK that should remain in the sender's account
    event SetRemnant(uint256 amount);

    /// @dev Emitted when a governor is added or removed. this is implemented by multi approve and executed by the majority of the governors
    /// @param governor The address of the governor
    /// @param status The status of the governor
    event Governor(address governor, bool status);

    modifier onlyGovernor() {
        bool isGovernor = false;
        for (uint256 i = 0; i < s_governors.length; i++) {
            if (s_governors[i] == _msgSender()) {
                isGovernor = true;
                break;
            }
        }
        require(isGovernor, "Mluck: not a governor");
        _;
    }

    constructor() ERC20("Mluck", "MLUCK") Ownable(msg.sender) {
        s_remnant = 1000 gwei;
        s_governors.push(_msgSender());
        s_approveThreshold = 50;
        _mint(msg.sender, 100_000_000 ether);
        renounceOwnership();
    }

    /**
     * @dev Pushes a request to the requests array, this request needs to have one of the request types
     * @param _requestType The type of request
     * @param _data The params for the executed function are encoded in the data field. this will be decoded in the _approveRequest function
     */
    function makeRequest(
        RequestType _requestType,
        bytes memory _data
    ) public onlyGovernor {
        validateRequest(_requestType, _data);
        bytes32 _id = keccak256(abi.encode(s_requests.length));
        Request memory request = Request(_id, 0, _requestType, false, _data);
        s_requests.push(request);
        emit MadeRequest(_requestType, _data, _id);
    }

    /**
     * @dev Approves a request, if the request is approved by the majority of the governors
     * the request will be executed
     * @param _id The id of the request
     *
     * Requirements:
     * - The request id should be valid
     * - The governor should not have voted before
     * - The request should not be executed before
     */
    function approveRequest(bytes32 _id) public onlyGovernor nonReentrant {
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < s_requests.length; i++) {
            if (s_requests[i].id == _id) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "Mluck: invalid request id");
        require(!s_voted[_id][_msgSender()], "Mluck: already voted");
        s_voted[_id][_msgSender()] = true;
        if (s_requests[index].executed) {
            s_requests[index].approved += 1;
            return;
        }
        _approveRequest(index);
    }

    /**
     * @dev Approves a request, if the request is approved by the majority of the governors
     * the request will be executed. This function is called privately by the approveRequest function
     * the function will loop through the requests array and check if the request is approved by the majority
     * if so the request's type will be checked and the corresponding function will be executed
     * the request will be marked as executed
     * @param _id The id of the request
     */
    function _approveRequest(uint256 _id) private {
        Request storage request = s_requests[_id];
        request.approved++;
        // checks if the request is approved by the major percentage of the governors
        if (request.approved * 100 >= s_approveThreshold * s_governors.length) {
            if (request.requestType == RequestType.MINT) {
                _handleMint(request.data);
            } else if (request.requestType == RequestType.WITHDRAW) {
                _withdraw(request);
            } else if (request.requestType == RequestType.GOVERNOR) {
                _handleGovernorRequest(request);
            } else if (request.requestType == RequestType.THRESHOLD) {
                _setApproveThreshold(abi.decode(request.data, (uint256)));
            } else if (request.requestType == RequestType.REMNANT) {
                _setRemnant(abi.decode(request.data, (uint256)));
            } else {
                revert("Mluck: invalid request type");
            }
            request.executed = true;
        }
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        address owner = _msgSender();
        value = _checkForRemnant(owner, value);
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom} and ERC20.transferFrom
     *
     * this function have been overridden to check for the remnant amount of MLK
     * that should remain in the sender's account after that can never be transferred or spent
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        value = _checkForRemnant(from, value);
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Check for the remnant amount of MLK that should remain in the sender's account after a transfer
     * @param _owner The address of the owner
     * @param _value The amount of MLK to transfer
     */
    function _checkForRemnant(
        address _owner,
        uint256 _value
    ) private view returns (uint256) {
        uint256 balance = balanceOf(_owner);
        require(_value <= balance, "Mluck: insufficient balance");
        require(_value >= s_remnant, "Mluck: remnant amount error");

        return _value <= balance - s_remnant ? _value : balance - s_remnant;
    }

    /**
     * @dev Set the remnant amount of MLK that should remain in the sender's account after a transfer
     * @param _remnant The least amount of MLK that should remain in the sender's account after a transfer
     */
    function _setRemnant(uint256 _remnant) private {
        s_remnant = _remnant;
        emit SetRemnant(_remnant);
    }

    /**
     * @dev This function is called by the approveRequest function if the majority of the governors
     * approve a request with the type GOVERNOR this function will add or remove a governor.
     * The data field is decoded to get the governor address and a boolean value to determine
     * if the governor should be added or removed
     * @param _request The request to handle
     */
    function _handleGovernorRequest(Request memory _request) private {
        (address _governor, bool _add) = abi.decode(
            _request.data,
            (address, bool)
        );
        if (_add) {
            _addGovernor(_governor);
        } else {
            _removeGovernor(_governor);
        }
    }

    /**
     * @dev Add a governor to the list of governors
     * @param _governor The address of the governor to add
     */
    function _addGovernor(address _governor) private {
        for (uint256 i = 0; i < s_governors.length; i++) {
            require(s_governors[i] != _governor, "Mluck: already a governor");
        }
        s_governors.push(_governor);
        emit Governor(_governor, true);
    }

    /**
     * @dev Remove a governor from the list of governors
     * @param _governor The address of the governor to remove
     */
    function _removeGovernor(address _governor) private {
        for (uint256 i = 0; i < s_governors.length; i++) {
            if (s_governors[i] == _governor) {
                s_governors[i] = s_governors[s_governors.length - 1];
                s_governors.pop();
                emit Governor(_governor, false);
                return;
            }
        }
        revert("Mluck: not a governor");
    }

    /**
     * @dev This function is called by the approveRequest function if the majority of the governors
     * approve a request with the type MINT this function will mint the given amount of MLK to the given address.
     * The data field is decoded to get the receiver address and the amount
     * @param _params The request data to handle
     */
    function _handleMint(bytes memory _params) private {
        (address _to, uint256 _amount) = abi.decode(
            _params,
            (address, uint256)
        );
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Mluck: max supply reached"
        );
        _mint(_to, _amount);
    }

    /**
     * @dev Set the threshold of approvals needed for a request to be executed.
     * This function is called internally by the approveRequest function.
     * @param _threshold The threshold of approvals needed for a request to be executed
     */
    function _setApproveThreshold(uint256 _threshold) private {
        s_approveThreshold = _threshold;
    }

    /**
     * @dev Withdraw the given amount of ERC20 tokens from contract balance
     * @dev This function is multi-sig and can only be called by approveRequest function
     * internally and automatically just after the request is approved by the majority of the governors
     * @param _request The request to handle. The data field is decoded to get the token address,
     * the receiver address, and the amount
     */
    function _withdraw(Request memory _request) private returns (bool success) {
        (address _token, address payable _to, uint256 _amount) = abi.decode(
            _request.data,
            (address, address, uint256)
        );
        require(
            _amount <= ERC20(_token).balanceOf(address(this)),
            "Mluck: insufficient balance"
        );

        success = ERC20(_token).transfer(_to, _amount);
        require(success, "Mluck: transfer failed");
        emit Withdraw(_to, _amount);
    }

    /// @dev Returns the list of all requests
    function requests() external view returns (Request[] memory) {
        return s_requests;
    }

    /// @dev Returns the list of governors
    function governors() external view returns (address[] memory) {
        return s_governors;
    }

    /// @dev Returns the remnant amount of MLK that should remain in the sender's account
    function remnant() external view returns (uint256) {
        return s_remnant;
    }

    /// @dev Returns the threshold of approvals needed for a request to be executed
    function approveThreshold() external view returns (uint256) {
        return s_approveThreshold;
    }

    /// @dev Returns if the given governor has voted for the given request id
    function voted(
        bytes32 _id,
        address _governor
    ) external view returns (bool) {
        return s_voted[_id][_governor];
    }
}
