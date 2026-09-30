// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Mock is IERC721 {
    string public name = "ERC721Mock";
    string public symbol = "M721";
    mapping(uint256 => address) public owners;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public tokenApprovals;

    function mint(address to, uint256 tokenId) external {
        owners[tokenId] = to;
        balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        return owners[tokenId];
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return balances[owner];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(owners[tokenId] == from, "Not owner");
        owners[tokenId] = to;
        balances[from] -= 1;
        balances[to] += 1;
        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        tokenApprovals[tokenId] = to;
        emit Approval(owners[tokenId], to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        return tokenApprovals[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external override {
        safeTransferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }
}