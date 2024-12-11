// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/**
 * @title MultiSigWallet (A multisignature (multisig) wallet is a type of cryptocurrency wallet that requires multiple private keys to authorize a transaction, offering enhanced security and shared control.) https://www.coinbase.com/learn/wallet/what-is-a-multi-signature-multi-sig-wallet
 * @author shurjeel 
 * @notice this contract is unaudited 
 */

contract MultiSigWallet {

    // Events to track activities in the contract
    event Deposit(address indexed sender, uint256 amount, uint256 balance); // Emitted on Ether deposits to the contract.
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data); // Emitted when a transaction is submitted.
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex); // Emitted when a transaction is confirmed.
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex); // Emitted when a confirmation is revoked.
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex); // Emitted when a transaction is executed.
    event ExecuteOwnerChange(address indexed oldOwner, address indexed newOwner, uint256 indexed txIndex); // Emitted when ownership is changed.
    event SubmiteOwnershipCompromised(address indexed compromisedOwner, address indexed newOwnerSuggested, uint256 indexed txIndex); // Emitted when ownership compromise is reported.
    event ConfrimOwnerCompromised(address indexed reportingOwner, address indexed ownerCompromised, uint256 txIndex); // Emitted when a compromise confirmation is submitted.

    // List of owners of the wallet
    address[] public owners;

    // Minimum number of confirmations required for executing transactions
    uint256 public numConfirmationsRequired;

    // Minimum number of confirmations required for ownership change due to compromise
    uint256 public numConfirmationsRequiredForOwnerToCompromised;

    // Structure to represent a transaction
    struct Transaction {
        address to; // Address to send the transaction to.
        uint256 value; // Amount of Ether to send.
        bytes data; // Additional data for the transaction.
        bool executed; // Status of execution.
        uint256 numConfirmations; // Number of confirmations received.
    }

    // Structure to represent an ownership change due to a compromised owner
    struct TransactionOwnerShipCompromised {
        address reportingOwner; // Address of the owner reporting the compromise.
        address compromisedOwner; // Address of the compromised owner.
        address newOwnerSuggested; // Address of the proposed new owner.
        bool executed; // Status of execution.
        uint256 numConfirmations; // Number of confirmations received.
    }

    // List of transactions submitted for execution
    Transaction[] public transactions;

    // List of ownership change proposals due to compromise
    TransactionOwnerShipCompromised[] public transactionsownerShipCompromised;

    // Mapping to check if an address is an owner
    mapping(address => bool) public isOwner;

    // Mapping to track confirmations for each transaction
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // Mapping to track confirmations for ownership compromise proposals
    mapping(uint256 => mapping(address => bool)) public isOwnerCompromised;

    // Modifier to restrict access to owners only
    modifier OnlyOwner() {
        require(isOwner[msg.sender] == true, "Multisig: not true owner");
        _;
    }

    // Modifier to ensure a transaction exists
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Multisig: tx doesn't exist");
        _;
    }

    // Modifier to ensure a transaction has not already been executed
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Multisig: tx already executed");
        _;
    }

    // Modifier to ensure a transaction has not already been confirmed by the caller
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    /**
     * @dev Constructor to initialize the multisig wallet.
     * @param _owners Array of wallet owner addresses.
     * @param _numConfirmationsRequired Minimum number of confirmations required for executing transactions.
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Multisig: invalid length"); // At least one owner is required.
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Multisig: invalid owner"); // Owners cannot be zero address.
            require(!isOwner[owner], "Multisig: owner not unique"); // Owners must be unique.

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @dev Fallback function to allow deposits.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev Function to submit a new transaction.
     * @param _to Destination address.
     * @param _value Amount of Ether to send.
     * @param _data Data payload for the transaction.
     */
    function submiteTransaction(address _to, uint256 _value, bytes memory _data) public OnlyOwner {
        uint256 txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /**
     * @dev Function to confirm a submitted transaction.
     * @param _txIndex Index of the transaction to confirm.
     */
    function confirmTransaction(uint256 _txIndex) public OnlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @dev Function to execute a confirmed transaction.
     * @param _txIndex Index of the transaction to execute.
     */
    function executeTransaction(uint256 _txIndex) public OnlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "Multisig: cannot execute tx");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @dev Function to revoke a confirmation for a transaction.
     * @param _txIndex Index of the transaction to revoke confirmation for.
     */
    function revokeConfirmation(uint256 _txIndex) public OnlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @dev Submit a proposal for ownership change due to compromise.
     * @param _ownerCompromised Address of the compromised owner.
     * @param _newOwnerSuggested Address of the proposed new owner.
     */
    function submiteOwnershipCompromised(address _ownerCompromised, address _newOwnerSuggested) public OnlyOwner {
        uint256 txIndex = transactionsownerShipCompromised.length;
        transactionsownerShipCompromised.push(
            TransactionOwnerShipCompromised({
                reportingOwner: msg.sender,
                compromisedOwner: _ownerCompromised,
                newOwnerSuggested: _newOwnerSuggested,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmiteOwnershipCompromised(_ownerCompromised, _newOwnerSuggested, txIndex);
    }

    /**
     * @dev Confirm an ownership change proposal.
     * @param _txIndex Index of the ownership change proposal to confirm.
     */
    function confrimOwnerCompromised(uint256 _txIndex) public OnlyOwner {
        require(!isOwnerCompromised[_txIndex][msg.sender], "MultiSig: already reported");
        TransactionOwnerShipCompromised storage transactionownerShipCompromised = transactionsownerShipCompromised[_txIndex];
        transactionownerShipCompromised.numConfirmations += 1;
        isOwnerCompromised[_txIndex][msg.sender] = true;
        
        emit ConfrimOwnerCompromised(msg.sender, transactionownerShipCompromised.compromisedOwner, _txIndex);
    }

    /**
     * @dev Execute an ownership change due to a confirmed compromise.
     * @param _txIndex Index of the ownership change proposal to execute.
     */
    function executeChangeOwner(uint256 _txIndex) public OnlyOwner {
        TransactionOwnerShipCompromised storage transactionownerShipCompromised = transactionsownerShipCompromised[_txIndex];
        require(transactionownerShipCompromised.numConfirmations >= numConfirmationsRequired, "Multisig: cannot execute tx");
        require(!transactionownerShipCompromised.executed, "Multisig: transaction already executed");

        address oldOwner = transactionownerShipCompromised.compromisedOwner;
        require(isOwner[oldOwner], "Not owner yet for rotation");

        isOwner[oldOwner] = false;
        isOwner[transactionownerShipCompromised.newOwnerSuggested] = true;

        owners.push(transactionownerShipCompromised.newOwnerSuggested);

        transactionownerShipCompromised.executed = true;
        
        emit ExecuteOwnerChange(transactionownerShipCompromised.compromisedOwner, transactionownerShipCompromised.newOwnerSuggested, _txIndex);
    }

      /**
     * @dev Returns the list of wallet owners.
     * @return An array of addresses representing the owners of the wallet.
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev Returns the total number of submitted transactions.
     * @return The count of transactions stored in the `transactions` array.
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev Retrieves the details of a specific transaction by its index.
     * @param _txIndex The index of the transaction in the `transactions` array.
     * @return to The address to which the transaction is directed.
     * @return value The Ether amount involved in the transaction.
     * @return data The data payload of the transaction.
     * @return executed A boolean indicating whether the transaction has been executed.
     * @return numConfirmations The number of confirmations the transaction has received.
     */
    function getTransactionIndex(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /**
     * @dev Returns the total number of ownership change proposals.
     * @return The count of proposals stored in the `transactionsownerShipCompromised` array.
     */
    function getOwnershipChangeProposalCount() public view returns (uint256) {
        return transactionsownerShipCompromised.length;
    }

    /**
     * @dev Retrieves the details of a specific ownership change proposal by its index.
     * @param _txIndex The index of the proposal in the `transactionsownerShipCompromised` array.
     * @return reportingOwner The owner who reported the compromised ownership.
     * @return compromisedOwner The address of the compromised owner.
     * @return newOwnerSuggested The address of the proposed new owner.
     * @return executed A boolean indicating whether the proposal has been executed.
     * @return numConfirmations The number of confirmations the proposal has received.
     */
    function getOwnershipChangeProposal(uint256 _txIndex)
        public
        view
        returns (
            address reportingOwner,
            address compromisedOwner,
            address newOwnerSuggested,
            bool executed,
            uint256 numConfirmations
        )
    {
        TransactionOwnerShipCompromised storage proposal = transactionsownerShipCompromised[_txIndex];

        return (
            proposal.reportingOwner,
            proposal.compromisedOwner,
            proposal.newOwnerSuggested,
            proposal.executed,
            proposal.numConfirmations
        );
    }

    /**
     * @dev Checks whether a specific owner has confirmed an ownership change proposal.
     * @param _txIndex The index of the ownership change proposal in the `transactionsownerShipCompromised` array.
     * @param _owner The address of the owner whose confirmation status is being checked.
     * @return A boolean indicating whether the owner has confirmed the proposal.
     */
    function isOwnershipChangeProposalConfirmed(uint256 _txIndex, address _owner)
        public
        view
        returns (bool)
    {
        return isOwnerCompromised[_txIndex][_owner];
    }

}
