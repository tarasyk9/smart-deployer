// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155Mock is IERC1155 {
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    function mint(address to, uint256 id, uint256 amount) external {
        balances[id][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return balances[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external override {
        require(balances[id][from] >= amount, "Not enough balance");
        balances[id][from] -= amount;
        balances[id][to] += amount;
        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
    {
        revert("Not implemented");
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
    }
}