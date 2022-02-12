pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./compound/ICErc20.sol";
import "./DrawLib.sol";

contract BasePool is ReentrancyGuard {

    using SafeMath for uint256;
    using Roles for Roles.Role;
    using DrawLib for DrawLib.DrawTree;

    DrawLib.DrawTree drawTree;

    struct Draw {
        uint256 openedBlock;
        // hashing random number, thus not able to modify after draw started
        bytes32 secretHash;
        // to check secret whether the hash value is matched with secretHash field
        bytes32 entropy;
        address winner;
        // winning prize
        uint256 netWinnings;
    }
    
    mapping(uint256 => Draw) internal Draws;

    uint256 public accountedBalance;
    mapping(address => uint256) internal balances;

    uint256 drawIndex;
    IcERC20 public cToken;

    // create Admin Role
    Roles.Role internal admins;

    event Opened(uint256 indexed drawId, bytes32 secretHash);
    event Deposited(address indexed sender, uint256 amount);
    event Rewarded(uint256 indexed drawId, address indexed winner, bytes32 entropy, uint256 netWinnings);
    event RewardFailed(uint256 indexed drawId);
    event Withdrawn(address indexed sender, uint256 amount);
    
    constructor (address _cToken) public {
        require(_cToken != address(0), "cToken address is required");
        cToken = IcERC20(_cToken);
        _addAdmin(msg.sender);
    }

    function _addAdmin(address _admin) internal {
        admins.add(_admin);
    }

    function addAdmin(address _admin) public onlyAdmin {
        _addAdmin(_admin);
    }

    function isAdmin(address _admin) public view returns (bool) {
        return admins.has(_admin);
    }

    modifier onlyAdmin() {
        require(admins.has(_admin), "the address does not have admin privileges");
        _;
    }

    function openDraw(bytes32 _secretHash) public onlyAdmin {
        require(currentOpenDrawId() == 0, "There is an ongoing opened draw already");
        drawTree.open();
        draws[drawTree.drawId] = Draw(block.number, _secretHash, bytes32(0), address(0), uint256(0));

        emit Opened(drawTree.drawId, _secretHash);
    }

    function currentOpenDrawId() public view returns (uint256) {
        if (drawTree.isOpened) {
            return drawTree.drawId;
        }
        return 0;
    }

    function buyTicket(uint256 _amount) public requireOpenDraw nonReentrant {
        // Transfer tokens into the contract
        require(token().transferFrom(msg.sender, address(this), _amount), "Transfer DAI is just failed");
        addTreeNode(msg.sender, _amount);

        _depositFrom(msg.sender, _amount);
        emit Deposited(msg.sender, _amount);
        // sending tokens to Compound pool from address(this)
        // Deposit the funds into Compound
    }

    function token() public view returns (IERC20) {
        return IERC20(cToken.underlying());
    }

    modifier requireOpenDraw() {
        require(currentOpenDrawId() != 0, "There is no opened, please open draw");
        _;
    }

    function addTreeNode(address _sender, uint256 amount) public requireOpenDraw onlyNonZero(_sender) {
        bytes32 userId = bytes32(uint256(_sender));
        bytes32 openDrawId = bytes32(currentOpenDrawId());
        
        uint256 currentAmount = drawTree.getDepositBalance(openDrawId, userId);
        currentAmount = currentAmount.add(_amount);
        drawTree.drawSet(openDrawId, currentAmount, userId);
    }

    modifier onlyNonZero(address _addr) {
        require(_addr != address(0), "Address should not be zero addr");
        _;
    }

    // address(this) to remit the approved token from _spender to Compound pool and mint cToken
    function _depositFrom(address _sender, uint256 _amount) internal {
        // update the user's balance
        balances[_sender] = balances[_sender].add(_amount);

        // update the total of this contract
        accountedBalance = accountedBalance.add(_amount);

        // Deposit into Compound
        require(token().approve(address(cToken), _amount), "Failed to approve when remitting token");
        // 0 == success
        require(cToken.mint(_amount) == 0, "Failed to mint cToken");
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function _withdraw(address _sender, uint256 _amount) internal {
        uint256 balance = balances[_sender];
        require(_amount <= balance, "cannot withdraw more tokens than your balance");

        // update the user's balance
        balances[_sender] = balance.sub(_amount);

        // udpate the total balance of the contract
        accountedBalance = accountedBalance.sub(_amount);

        // Withdraw from Compound Pool and Transfer to Users
        require(cToken.redeemUnderlying(_amount) == 0, "failed to redeem cDAI back to contract");
        require(token().transfer(_sender, _amount), "failed to transfer back cDAI to user");
    }

    function withdrawDeposit(uint256 _amount) public {
        bytes32 userId = bytes32(uint256(msg.sender));
        bytes32 openDrawId = bytes32(currentOpenDrawId());

        uint256 deposit = balances[msg.sender].sub(drawTree.getDepositBalance(openDrawId, userId);)
        require(_amount <= deposit, "cannot withdraw more deposit than your balances");

        _withdraw(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function reward(bytes32 _secret, bytes32 _salt) public onlyAdmin requireOpenDraw nonReentrant {
        uint256 drawId = currentOpenDrawId();
        Draw storage draw = draws[drawId];
        
        closeCurrentOpenDraw();

        require(draw.secretHash == keccak256(abi.encodePacked(_secret, _salt)), "Secret is incorrect");

        // derive entropy from the revealed secret
        bytes32 entropy = keccak256(abi.encodePacked(_secret));

        // Select the winner using the has as entropy
        address winningAddress = pickWinner(entropy, drawId);

        // calculate the gross winnings
        uint256 netWinnings = 0;
        uint256 grossWinnings = 0;

        uint256 fee = 0; // 수수료
        uint256 underlyingBalance = balanceOfUnderlying();

        if (underlyingBalance > accountedBalance) {
            grossWinnings = underlyingBalance.sub(accountedBalance);
        }

        // no fees!
        netWinnings = grossWinnings.sub(fee);

        draw.winner = winningAddress;
        draw.netWinnings = netWinnings;
        draw.entropy = entropy;

        if (winningAddress != address(0) && netWinnings > 0) {
            // updated the accounted total
            accountedBalance = underlyingBalance

            // updated balance of the winer
            balances[winningAddress] = balances[winningAddress].add(netWinnings);

            uint256 currentAmount = drawTree.getDepositBalance(bytes32(drawId), bytes32(uint256(winningAddress)));
            currentAmount = currentAmount.add(netWinnings);
            drawTree.drawSet(bytes32(drawId), currentAmount, bytes32(uint256(winningAddress)));

            emit Rewarded(drawId, winningAddress, entropy, netWinnings);
            return;
        }

        emit RewardFailed(drawId);
        return;
    }

    function balanceOfUnderlying() public returns (uint256) {
        return cToken.balanceOfUnderlying(address(this));
    }

    function closeCurrentOpenDraw() internal {
        if (drawTree.isOpened) {
            drawTree.isOpened = false;
        }
    }

    function pickWinner(bytes32 _entropy, uint256 _drawId) public view returns (address) {
        return drawTree.drawWithEntropy(_entropy, bytes32(_drawId));
    }

    function getTotalOfDrawTree(uint256 drawId) external view returns (uint256) {
        return drawTree.total(bytes32(drawId));
    }

    function getBalanceOfDrawTree(address _addr) external view returns (uint256) {

        bytes32 userId = bytes32(uint256(_addr));
        bytes32 openDrawId = bytes32(currentOpenDrawId());

        return drawTree.getDepositBalance(openDrawId, userId);
    }

    function getBalanceOfDrawTreeById(uint256 _drawId, address _addr) external view returns (uint256) {

        bytes32 drawId = bytes32(_drawId);
        bytes32 userId = bytes32(uint256(_addr));

        return drawTree.getDepositBalance(drawId, userId);
    }

    function kill() external onlyAdmin {
        selfdestruct();
    }

    function getDraw(uint256 _drawId) external view returns (
        uint256 openedBlock,
        bytes32 secretHash,
        bytes32 entropy,
        address winner,
        uint256 netWinnings
    ) {
        Draw storage draw = draws[_drawId];
        openedBlock = draw.openedBlock;
        secretHash = draw.secretHash;
        entropy = draw.entropy;
        winner = draw.winner;
        netWinnings = draw.netWinnings;
    }
}