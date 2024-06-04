# MLUCK

![Mluck Contract](./images/mluck.png)

## Description

Mluck is an ERC20 token with unique governance features. It includes functionalities for remnant balance, multi-signature approvals, and governor management. The initial supply is 100,000,000 MLK, and the maximum supply is capped at 1,000,000,000 MLK.

## Table of Contents

1. [Introduction](#introduction)
2. [Features](#features)
3. [Getting Started](#getting-started)
   - [Prerequisites](#prerequisites)
   - [Installation](#installation)
   - [Configuration](#configuration)
4. [Usage](#usage)
   - [Running Tests](#running-tests)
   - [Deploying Contracts](#deploying-contracts)
   - [Interacting with Contracts](#interacting-with-contracts)
5. [Directory Structure](#directory-structure)
6. [Contributing](#contributing)
7. [License](#license)

## Introduction

Mluck is a standard ERC20 token with additional governance and security features. It allows for multi-signature requests by governors for minting, withdrawing, and managing other critical operations.

## Features

- **Remnant Balance**: Ensures a minimum balance remains in accounts.
- **Governor Management**: Allows for adding and removing governors.
- **Multi-Signature Approvals**: Requests for critical operations require approval from multiple governors.
- **Withdraw Funds**: Governors can withdraw funds from the contract.

## Getting Started

### Prerequisites

- Node.js
- npm
- Hardhat

### Installation

```sh
# Clone the repository
git clone https://github.com/Mluck-Digital/smart-contracts.git

# Navigate to the project directory
cd smart-contracts

# Install dependencies
npm install
```

### Configuration

Create a .env file in the root directory and add the following variables:

```sh
PRIVATE_KEY=your_private_key
LEDGER_ACCOUNT=ledger_account
BSC_RPC=binance_smart_chain_rpc_url
TBSC_RPC=test_binance_smart_chain_rpc_url
```

You can see an example of .env file in the .example.env file.

## Usage

### Running Tests

```sh
# Run all tests
npx hardhat test
```

### Deploying Contracts

```sh
# Compile the contracts
npx hardhat compile

# Deploy the contracts to the Binance Smart Chain testnet
npm run deploy:mluck:testnet

# Deploy the contracts to the Binance Smart Chain mainnet
npm run deploy:mluck
```

### Interacting with Contracts

Interact with the deployed contracts using the Hardhat console or scripts.

```lua
.
├── contracts
│   ├── tokens
│   │   ├── IMluck.sol
│   │   └── Mluck.sol
│   ├── utils
│   │   ├── enums
│   │   │   └── RequestType.sol
│   │   ├── structs
│   │   │    └── Request.sol
│   │   └── ValidateRequest.sol
├── scripts
│   └── mluck.deploy.js
├── test
│   └── mluck.test.js
├── hardhat.config.js
├── .env
├── .example.env
├── .gitignore
├── package-lock.json
├── package.json
└── README.md
```

## Contributing

We are not open to contributions at the moment. However, you can fork the repository and make changes to your version.
And also you can create an issue if you find any bug or have a feature request.

## License

This project is licensed under the MIT License.
