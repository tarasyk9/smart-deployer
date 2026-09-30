// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {ERC1155Airdroper} from "src/ERC1155Airdroper/ERC1155Airdroper.sol";
import {ERC1155Mock} from "./ERC1155Mock.sol";
import {MockDeployManager} from "test/DeployManager/MockDeployManager.sol";
import {DeployManager} from "src/DeployManager/DeployManager.sol";
import {IDeployManager} from "src/DeployManager/IDeployManager.sol";

contract ERC1155AirdroperTest is Test {
    ERC1155Airdroper public airdroper;
    ERC1155Mock public token;
    MockDeployManager public mockDeployManager;
    address public airdropOwner;
    address public treasury;
    address public managerOwner;
    address[] public receivers;
    uint256[] public tokenIds;
    uint256[] public amounts;

    receive() external payable {}

    function setUp() public {
        airdropOwner = vm.addr(1);
        treasury = vm.addr(2);
        managerOwner = vm.addr(42);
        receivers = new address[](3);
        tokenIds = new uint256[](3);
        amounts = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            receivers[i] = vm.addr(3 + i);
            tokenIds[i] = 100 + i;
            amounts[i] = 10 * (i + 1);
        }
        token = new ERC1155Mock();
        airdroper = new ERC1155Airdroper();
        mockDeployManager = new MockDeployManager();
        for (uint256 i = 0; i < 3; i++) {
            token.mint(treasury, tokenIds[i], amounts[i]);
        }
        vm.prank(treasury);
        token.setApprovalForAll(address(airdroper), true);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), treasury, airdropOwner);
        airdroper.initialize(initData);
    }

    function testAirdropSuccess() public {
        vm.prank(airdropOwner);
        airdroper.airdrop(receivers, amounts, tokenIds);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(token.balanceOf(receivers[i], tokenIds[i]), amounts[i], "Receiver should get correct amount");
        }
    }

    function testAirdropBatchSizeExceeded() public {
        address[] memory bigReceivers = new address[](11);
        uint256[] memory bigTokenIds = new uint256[](11);
        uint256[] memory bigAmounts = new uint256[](11);
        for (uint256 i = 0; i < 11; i++) {
            bigReceivers[i] = vm.addr(1000 + i);
            bigTokenIds[i] = 10000 + i;
            bigAmounts[i] = 1;
        }
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(bigReceivers, bigAmounts, bigTokenIds);
    }

    function testAirdropReceiversLengthMismatch() public {
        address[] memory badReceivers = new address[](2);
        uint256[] memory badTokenIds = new uint256[](3);
        uint256[] memory badAmounts = new uint256[](3);
        badReceivers[0] = vm.addr(10);
        badReceivers[1] = vm.addr(11);
        badTokenIds[0] = 1;
        badTokenIds[1] = 2;
        badTokenIds[2] = 3;
        badAmounts[0] = 1;
        badAmounts[1] = 2;
        badAmounts[2] = 3;
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(badReceivers, badAmounts, badTokenIds);
    }

    function testAirdropAmountsLengthMismatch() public {
        address[] memory badReceivers = new address[](3);
        uint256[] memory badTokenIds = new uint256[](3);
        uint256[] memory badAmounts = new uint256[](2);
        for (uint256 i = 0; i < 3; i++) {
            badReceivers[i] = vm.addr(20 + i);
            badTokenIds[i] = 200 + i;
        }
        badAmounts[0] = 1;
        badAmounts[1] = 2;
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(badReceivers, badAmounts, badTokenIds);
    }

    function testAirdropNotApproved() public {
        vm.prank(treasury);
        token.setApprovalForAll(address(airdroper), false);
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(receivers, amounts, tokenIds);
    }

    function testTemplateIsNotInitialized() public {
        ERC1155Airdroper template = new ERC1155Airdroper();
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
