# MultiSig Wallet

<p align="center">
  <img src="./img/multi_sig_logo.webp" width="600" height="600" />
</p>


This repository contains a Solidity-based implementation of a MultiSig wallet contract, along with a comprehensive suite of tests written using Foundry, a fast and modular toolkit for Ethereum application development.

The MultiSig wallet allows multiple owners to collectively manage funds and execute transactions. It also provides functionality to replace compromised owners with new ones through a proposal and voting mechanism.

---

## Features

- **Multi-owner management:** Transactions require confirmation from a predefined number of owners.
- **Ownership change proposals:** Owners can propose replacing a compromised owner, which requires confirmations from other owners.
- **Transaction lifecycle:** Supports submitting, confirming, revoking, and executing transactions.
- **Robust tests:** Includes a complete suite of test cases using Foundry to ensure functionality and edge case coverage.

---

## Prerequisites

- **Foundry:** Install Foundry by following the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).
- **Solidity Compiler:** Ensure the Solidity compiler version `^0.8.25` is installed.

---

## Getting Started

### Clone the Repository
```bash
git clone https://github.com/YourGuyD3v/MultiSig-Wallet.git
cd multisig-wallet
```

## Install Dependencies

Foundry manages dependencies through forge install. If required, initialize a Foundry project and install dependencies:
```bash
forge install
```

## Build the Project

Compile the contract using Forge:
```bash
forge build
```

## Run Tests
Execute the comprehensive test suite:
```bash
forge test
```

## Contract Overview
### MultiSigWallet.sol
The main smart contract implements a multi-signature wallet with the following features:

### Constructor
Initializes the wallet with a set of owners and a minimum number of confirmations required.

### Functions

**Transaction Management:**

- ```submitTransaction:``` Allows owners to propose a new transaction.  
- ```confirmTransaction:``` Owners can confirm a submitted transaction.  
- ```revokeConfirmation:``` Owners can revoke their confirmation for a transaction.  
- ```executeTransaction:``` Executes a transaction if it has enough confirmations.  

**Ownership Management:**

- ```submitOwnershipCompromised:``` Propose replacing a compromised owner.  
- ```confirmOwnerCompromised:``` Confirm the replacement of a compromised owner.  
- ```executeChangeOwner:``` Execute the owner replacement proposal if enough confirmations are received.  

**Utility Functions:**

- Getter functions for retrieving transaction and proposal details.

### MultiSigTest.sol
This file contains comprehensive test cases for all functionalities of the MultiSigWallet contract. It uses Foundry's Test module to ensure correctness under various scenarios, including edge cases and failure conditions.

## Testing Framework: Foundry
Foundry is a fast, portable, and modular Ethereum development toolkit. It is used in this project for testing and development.

### Key Foundry Commands

Build the project:
```bash
forge build
```

Run tests:
```bash
forge test
```

Format code:
```bash
forge fmt
```

Gas snapshots:
```bash
forge snapshot
```

Deploy contracts:
```bash
forge script script/YourScript.s.sol:YourScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## File Structure

```bash
├── src
│   └── MultiSigWallet.sol    # Main contract
├── test
│   └── MultiSigTest.sol      # Foundry-based test suite
├── script                    # Deployment scripts
├── foundry.toml              # Foundry configuration
└── README.md                 # Project documentation
```

## Usage

### Deploy the Contract

Deploy the contract using Foundry’s script feature:
```bash
forge script script/DeployMultiSig.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Interact with the Contract

Use Foundry's cast tool to interact with the deployed contract:
```bash
cast call <contract_address> "getOwners()"
```

## Contribution
Contributions are welcome! Please open an issue or create a pull request with your proposed changes.

## License
This project is licensed under the MIT License.

Resources
Foundry Documentation
Solidity Documentation
Ethereum Development Best Practices

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Solidity Documentation](https://soliditylang.org/docs/)
- [Ethereum Development Best Practices](https://ethereum.org/en/developers/docs/)
