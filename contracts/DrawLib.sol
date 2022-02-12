pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SortitionSumTreeFactory.sol";
import "./UniformRandomNumber.sol";


library DrawLib {

    using SafeMath for uint256;
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

    uint256 public constant MAX_BRANCHES_PER_NODE = 2;

    struct DrawTree {
        
        SortitionSumTreeFactory.SortitionSumTrees sumTrees;
        uint256 drawId; // now currently drawing stage
        bool isOpened; // whether drawing now or not
    }

    function open(DrawTree storage _self) internal {
        
        _self.drawId = _self.drawId.add(1);
        _self.isOpened = true;
        bytes32 key = bytes32(_self.drawId);

        _self.sumTrees.createTree(key, MAX_BRANCHES_PER_NODE);
    }

    function drawSet(DrawTree storage _self, bytes32 _drawId, uint256 _amount, bytes32 userId) internal {

        uint256 oldAmount = _self.sumTrees.stakeOf(_drawId, userId);
        if (oldAmount != _amount) {
            _self.sumTrees.set(_drawId, _amount, userId);
        }
    }

    function getDepositBalance(DrawTree storage _self, bytes32 _drawId, bytes32 userId) internal view returns (uint256) {
        return _self.sumTrees.stakeOf(_drawId, userId);
    }

    function total(DrawTree storage _self, bytes32 _drawId) internal view returns (uint256){
        return _self.sumTrees.total(_drawId);
    }

    // choose the winner
    function drawWithEntropy(DrawTree storage _self, bytes32 _entropy, bytes32 _drawId) internal view returns (address) {

        uint256 bound = total(_self, _drawId);
        address selected;

        if (bound == 0){
            selected = address(0);
        } else {
            uint256 random = UniformRandomNumber.uniform(uint256(_entropy), bound);
            selected = address(uint256(_self.sumTrees.draw(_drawId, random)));
        }

        return selected;
    }
}