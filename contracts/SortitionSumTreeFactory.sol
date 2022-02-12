pragma solidity ^0.6.0;

library SortitionSumTreeFactory {
    struct SortitionSumTree {
        // THe maximum num of childs per node
        uint K;
        uint[] nodes;
        // to keep track of vacant positions in the tree
        // after removing a leaf
        // keeping the tree as balanced as possible w.o. spending gas
        // moving nodes around
        uint[] stack;
        // root node index
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIds;
    }
    
    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }
    
    // create a sortition sum tree at the specified key
    // @param _key = the key of the new tree
    // @param _K = the number of children each node in the tree
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greather than one.");
        tree.K = _K;
        // setting root node
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }
    
    // set a value of a tree
    // @param _key = the key of the tree
    // @param _value = the new value
    // @param _ID = the id of the value
    // O(log_k(n)) where K = the MAX number of childs per node in the tree
    // where n = the MAX number of nodes ever appended.
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];
        
        // No Existing Node
        if (treeIndex == 0) {
            // Non Zero Value
            if (_value != 0) {
                // no vacant spots
                if (tree.stack.length == 0) {
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);
                    // make the parent a sum node, if new node is the orphan node
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) {
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIds[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);

                        delete tree.nodeIndexesToIds[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIds[newIndex] = parentID;
                    }
                }
            }
            // add new node label to the introduced value
            tree.IDsToNodeIndexes[_ID] = treeIndex;
            tree.nodeIndexesToIds[treeIndex] = _ID;
            updateParents(self, _key, treeIndex, true, _value);
        }
    }

    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns (uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) {
            value = 0;
        } else {
            value = tree.nodes[treeIndex];
        }
    }

    function pickWinner(SortitionSumTrees storage self, bytes32 _key, uint drawnNumber) public view returns (bytes32) {
        return draw(self, _key, drawnNumber);
    }

    function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }
    
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        
        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length) {  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        }
        ID = tree.nodeIndexesToIds[treeIndex];
        return ID;
    }
}
