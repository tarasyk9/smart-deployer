// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import {ERC721Airdroper} from "src/ERC721Airdroper/ERC721Airdroper.sol";
import {ERC721Mock} from "./ERC721Mock.sol";
import {MockDeployManager} from "test/DeployManager/MockDeployManager.sol";
import {DeployManager} from "src/DeployManager/DeployManager.sol";
import {IDeployManager} from "src/DeployManager/IDeployManager.sol";

contract ERC721AirdroperTest is Test {
    ERC721Airdroper public airdroper;
    ERC721Mock public token;
    MockDeployManager public mockDeployManager;
    address public airdropOwner;
    address public treasury;
    address public managerOwner;
    address[] public receivers;
    uint256[] public tokenIds;

    receive() external payable {}

    function setUp() public {
        airdropOwner = vm.addr(1);
        treasury = vm.addr(2);
        managerOwner = vm.addr(42);
        receivers = new address[](3);
        tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            receivers[i] = vm.addr(3 + i);
            tokenIds[i] = 100 + i;
        }
        token = new ERC721Mock();
        airdroper = new ERC721Airdroper();
        mockDeployManager = new MockDeployManager();
        for (uint256 i = 0; i < 3; i++) {
            token.mint(treasury, tokenIds[i]);
        }
        vm.prank(treasury);
        token.setApprovalForAll(address(airdroper), true);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), treasury, airdropOwner);
        airdroper.initialize(initData);
    }

    function testAirdropSuccess() public {
        vm.prank(airdropOwner);
        airdroper.airdrop(receivers, tokenIds);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(token.ownerOf(tokenIds[i]), receivers[i], "Receiver should own token");
        }
    }

    function testAirdropBatchSizeExceeded() public {
        address[] memory bigReceivers = new address[](301);
        uint256[] memory bigTokenIds = new uint256[](301);
        for (uint256 i = 0; i < 301; i++) {
            bigReceivers[i] = vm.addr(1000 + i);
            bigTokenIds[i] = 10000 + i;
        }
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(bigReceivers, bigTokenIds);
    }

    function testAirdropArraysLengthMismatch() public {
        address[] memory badReceivers = new address[](2);
        uint256[] memory badTokenIds = new uint256[](3);
        badReceivers[0] = vm.addr(10);
        badReceivers[1] = vm.addr(11);
        badTokenIds[0] = 1;
        badTokenIds[1] = 2;
        badTokenIds[2] = 3;
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(badReceivers, badTokenIds);
    }

    function testAirdropNotApproved() public {
        // Remove approval
        vm.prank(treasury);
        token.setApprovalForAll(address(airdroper), false);
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(receivers, tokenIds);
    }

    function testTemplateIsNotInitialized() public {
        ERC721Airdroper template = new ERC721Airdroper();
        assertFalse(template.initialized(), "Template should not be initialized");
    }

    function testDeployManagerSupportsInterfaceDirect() public {
        DeployManager deployManager = new DeployManager();
        bytes4 iface = type(IDeployManager).interfaceId;
        bool result = deployManager.supportsInterface(iface);
        assertTrue(result, "DeployManager should support IDeployManager interface");
    }

    function encodeInitData(address _deployManager, address _token, address _treasury, address _owner)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _treasury, _owner);
    }
}
