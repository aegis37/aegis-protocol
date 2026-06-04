// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AegisPool
 * @notice Shielded transaction pool for mixing and anonymizing transactions
 * @dev Mixes deposits and enables private withdrawals
 */
contract AegisPool {
    string public constant name = "AEGIS Shielded Pool";
    string public constant version = "1.0.0";
    
    uint256 public constant MIN_DEPOSIT = 0.001 ether;
    uint256 public constant MAX_DEPOSIT = 100 ether;
    
    /// @notice Emitted when a deposit is made to the pool
    event Deposited(
        address indexed depositor,
        bytes32 indexed commitment,
        uint256 amount,
        uint256 timestamp
    );
    
    /// @notice Emitted when a withdrawal is made from the pool
    event Withdrawn(
        address indexed recipient,
        bytes32 nullifier,
        uint256 amount,
        uint256 timestamp
    );
    
    /// @notice Emitted when a relayer executes a private withdrawal
    event RelayerWithdraw(
        address indexed relayer,
        address indexed recipient,
        bytes32 nullifier,
        uint256 amount,
        uint256 gasFee
    );
    
    /// @dev Merkle tree for commitments
    uint256 public nextLeafIndex;
    bytes32 public currentRoot;
    bytes32[] public roots;
    
    /// @dev Store commitments
    mapping(uint256 => bytes32) public commitments;
    
    /// @dev Track nullifiers (spent or not)
    mapping(bytes32 => bool) public spentNullifiers;
    
    /// @dev Relayer address (for private withdrawals via relayer)
    address public relayer;
    
    /// @dev Fee percentage for relayer (in basis points, 100 = 1%)
    uint256 public relayerFeeBps = 100; // 1%
    
    /// @dev Contract owner
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "AegisPool: unauthorized");
        _;
    }
    
    modifier onlyRelayer() {
        require(msg.sender == relayer, "AegisPool: unauthorized relayer");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        relayer = msg.sender;
    }
    
    /**
     * @notice Deposit ETH into the shielded pool
     * @param _commitment Hash of (amount + secret)
     */
    function deposit(bytes32 _commitment) external payable {
        uint256 amount = msg.value;
        
        require(amount >= MIN_DEPOSIT, "AegisPool: below minimum");
        require(amount <= MAX_DEPOSIT, "AegisPool: above maximum");
        require(_commitment != bytes32(0), "AegisPool: invalid commitment");
        
        // Store commitment
        commitments[nextLeafIndex] = _commitment;
        nextLeafIndex++;
        
        // Update merkle root (simplified - in production use actual merkle tree)
        currentRoot = _hashPair(_commitment, currentRoot);
        if (roots.length == 0 || roots.length > 100) {
            roots.push(currentRoot);
        }
        
        emit Deposited(msg.sender, _commitment, amount, block.timestamp);
    }
    
    /**
     * @notice Withdraw using ZK proof via relayer
     * @param _nullifier Unique nullifier (hash of secret)
     * @param _recipient Final recipient address
     * @param _amount Amount to withdraw
     * @param _proof ZK proof
     * @param _root Merkle root to verify commitment exists
     */
    function withdraw(
        bytes32 _nullifier,
        address _recipient,
        uint256 _amount,
        bytes calldata _proof,
        bytes32 _root
    ) external {
        require(!spentNullifiers[_nullifier], "AegisPool: nullifier already spent");
        require(_recipient != address(0), "AegisPool: invalid recipient");
        require(_amount >= MIN_DEPOSIT, "AegisPool: below minimum");
        
        // In production: verify ZK proof + merkle proof here
        // _verifyProof(_proof, _nullifier, _root);
        
        spentNullifiers[_nullifier] = true;
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AegisPool: transfer failed");
        
        emit Withdrawn(_recipient, _nullifier, _amount, block.timestamp);
    }
    
    /**
     * @notice Relayer-enabled withdrawal (pay gas fees in privacy)
     * @param _nullifier Nullifier
     * @param _recipient Recipient
     * @param _amount Amount
     * @param _proof ZK proof
     * @param _root Merkle root
     * @param _gasPrice Gas price for relayer
     */
    function relayerWithdraw(
        bytes32 _nullifier,
        address _recipient,
        uint256 _amount,
        bytes calldata _proof,
        bytes32 _root,
        uint256 _gasPrice
    ) external onlyRelayer {
        require(!spentNullifiers[_nullifier], "AegisPool: nullifier already spent");
        require(_recipient != address(0), "AegisPool: invalid recipient");
        
        // Calculate fee
        uint256 fee = (_amount * relayerFeeBps) / 10000;
        uint256 withdrawAmount = _amount - fee;
        
        spentNullifiers[_nullifier] = true;
        
        // Transfer to recipient
        (bool success1, ) = _recipient.call{value: withdrawAmount}("");
        require(success1, "AegisPool: recipient transfer failed");
        
        // Transfer fee to relayer
        (bool success2, ) = relayer.call{value: fee}("");
        require(success2, "AegisPool: relayer transfer failed");
        
        emit RelayerWithdraw(relayer, _recipient, _nullifier, withdrawAmount, fee);
    }
    
    /**
     * @notice Set relayer address
     * @param _relayer New relayer address
     */
    function setRelayer(address _relayer) external onlyOwner {
        require(_relayer != address(0), "AegisPool: invalid relayer");
        relayer = _relayer;
    }
    
    /**
     * @notice Set relayer fee
     * @param _feeBps New fee in basis points
     */
    function setRelayerFee(uint256 _feeBps) external onlyOwner {
        require(_feeBps <= 1000, "AegisPool: fee too high"); // max 10%
        relayerFeeBps = _feeBps;
    }
    
    /**
     * @notice Check if nullifier is spent
     * @param _nullifier Nullifier to check
     * @return Whether nullifier is spent
     */
    function isSpent(bytes32 _nullifier) external view returns (bool) {
        return spentNullifiers[_nullifier];
    }
    
    /**
     * @notice Get current merkle root index
     * @return Current leaf index
     */
    function getNextLeafIndex() external view returns (uint256) {
        return nextLeafIndex;
    }
    
    /// @dev Internal: hash two values together (simplified merkle)
    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }
    
    /// @dev View function to get pool balance
    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }
}