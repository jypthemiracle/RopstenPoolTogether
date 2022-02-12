pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./SortitionSumTreeFactory.sol";
import "./UniformRandomNumber.sol";

contract SortitionSumTreeFactoryTest {

    using SafeMath for uint256;
	using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
	SortitionSumTreeFactory.SortitionSumTrees trees;
	
	bytes32 public constant TREE_OF_DRAWS = "FairDraw";
	uint256 public constant MAX_BRANCHES_PER_NODE = 2;
	
	constructor() public {
		trees.createTree(TREE_OF_DRAWS, MAX_BRANCHES_PER_NODE);
	}
    
    function totalSum() public view returns (uint256) {
        return trees.total(TREE_OF_DRAWS);
    }
    
    function addNode(address _addr, uint256 _amount) external {
        bytes32 userId = bytes32(uint256(_addr));
        trees.set(TREE_OF_DRAWS, _amount, userId);
    }

    function pickWinnerEntropy(uint drawnNumber) public view returns (address) {
        uint256 bound = totalSum();
        if (bound == 0){
            return address(0);
        }
        uint256 random = UniformRandomNumber.uniform(uint256(drawnNumber), bound);
        return address(uint256(trees.pickWinner(TREE_OF_DRAWS, drawnNumber)));
    }

    function pickWinner(uint drawnNumber) public view returns (address) {
        uint256 bound = totalSum();
        if (bound == 0){
            return address(0);
        }
        return address(uint256(trees.pickWinner(TREE_OF_DRAWS, drawnNumber)));
    }
}