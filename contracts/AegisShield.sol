// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AegisShield
 * @notice Core privacy vault for AEGIS protocol
 * @dev Enables private deposits and transfers on Base
 */
contract AegisShield {
    string public constant name = "AEGIS Shield";
    string public constant version = "1.0.0";
    
    /// @notice Emitted when a private deposit is made
    event PrivateDeposit(
        address indexed depositor,
        uint256 indexed commitment,
        uint256 amount
    );
    
    /// @notice Emitted when a private transfer is executed
    event PrivateTransfer(
        uint256 indexed nullifier,
        address indexed recipient,
        uint256 amount
    );
    
    /// @notice Emitted when a withdrawal is made
    event Withdrawal(
        address indexed recipient,
        uint256 indexed nullifier,
        uint256 amount
    );
    
    /// @dev Mapping to track used nullifiers (prevent double-spend)
    mapping(uint256 => bool) public nullifiers;
    
    /// @dev Mapping to track commitments
    mapping(uint256 => bool) public commitments;
    
    /// @dev Total private TVL
    uint256 public totalPrivateTVL;
    
    /// @dev Contract owner (temporarily for admin functions)
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "AegisShield: unauthorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @notice Deposit ETH into the privacy pool
     * @param _commitment The commitment hash (hash of depositor + amount + secret)
     */
    function deposit(bytes32 _commitment) external payable {
        require(msg.value > 0, "AegisShield: zero deposit");
        require(!commitments[uint256(_commitment)], "AegisShield: commitment already exists");
        
        commitments[uint256(_commitment)] = true;
        totalPrivateTVL += msg.value;
        
        emit PrivateDeposit(msg.sender, uint256(_commitment), msg.value);
    }
    
    /**
     * @notice Execute a private transfer (requires ZK proof in production)
     * @param _nullifier Unique nullifier to prevent double-spend
     * @param _recipient Recipient address
     * @param _amount Amount to transfer
     * @param _proof ZK proof (simplified for MVP)
     */
    function transfer(
        bytes32 _nullifier,
        address _recipient,
        uint256 _amount,
        bytes calldata _proof
    ) external {
        require(!nullifiers[uint256(_nullifier)], "AegisShield: nullifier already used");
        require(_recipient != address(0), "AegisShield: invalid recipient");
        require(_amount > 0, "AegisShield: zero transfer");
        
        // In production: verify ZK proof here
        // _verifyProof(_proof, _amount, _nullifier);
        
        nullifiers[uint256(_nullifier)] = true;
        
        emit PrivateTransfer(uint256(_nullifier), _recipient, _amount);
    }
    
    /**
     * @notice Withdraw funds from the privacy pool
     * @param _nullifier Nullifier proving the deposit
     * @param _recipient Recipient address
     * @param _amount Amount to withdraw
     * @param _proof ZK proof
     * @param _root Merkle root of the commitment tree
     */
    function withdraw(
        bytes32 _nullifier,
        address _recipient,
        uint256 _amount,
        bytes calldata _proof,
        bytes32 _root
    ) external {
        require(!nullifiers[uint256(_nullifier)], "AegisShield: nullifier already used");
        require(_recipient != address(0), "AegisShield: invalid recipient");
        require(_amount > 0, "AegisShield: zero withdrawal");
        
        // In production: verify ZK proof + merkle proof
        // require(_verifyMerkleProof(_root, commitment), "AegisShield: invalid merkle root");
        
        nullifiers[uint256(_nullifier)] = true;
        totalPrivateTVL -= _amount;
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AegisShield: transfer failed");
        
        emit Withdrawal(_recipient, uint256(_nullifier), _amount);
    }
    
    /**
     * @notice View function to check if a nullifier is used
     * @param _nullifier The nullifier to check
     * @return Whether the nullifier is spent
     */
    function isSpentNullifier(bytes32 _nullifier) external view returns (bool) {
        return nullifiers[uint256(_nullifier)];
    }
    
    /**
     * @notice Get contract balance
     * @return Current ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}