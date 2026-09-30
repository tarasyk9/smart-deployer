// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {ERC20Airdroper} from "src/ERC20Airdroper/ERC20Airdroper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployManager} from "src/DeployManager/DeployManager.sol";
import {IDeployManager} from "src/DeployManager/IDeployManager.sol";
import {ERC20Mock} from "../ERC20Airdroper/ERC20Mock.sol";
import {MockDeployManager} from "../DeployManager/MockDeployManager.sol";

contract ERC20AirdroperTest is Test {
    ERC20Airdroper public airdroper;
    ERC20Mock public token;
    address public airdropOwner;
    address public treasury;
    address public managerOwner;
    address[] public receivers;
    uint256[] public amounts;
    MockDeployManager mockDeployManager;

    receive() external payable {}

    function setUp() public {
        airdropOwner = vm.addr(1);
        treasury = vm.addr(2);
        managerOwner = vm.addr(42);
        receivers = new address[](3);
        amounts = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            receivers[i] = vm.addr(3 + i);
            amounts[i] = 100 * (i + 1);
        }
        token = new ERC20Mock();
        airdroper = new ERC20Airdroper();
        mockDeployManager = new MockDeployManager();
        mockDeployManager.setSupports(true);
        token.mint(treasury, 1000);
        vm.prank(treasury);
        token.approve(address(airdroper), 1000);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), 1000, treasury, airdropOwner);
        airdroper.initialize(initData);
        vm.deal(managerOwner, 0);
    }

    function testDeployManagerSupportsInterface() public {
        // Should succeed with supports = true
        mockDeployManager.setSupports(true);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), 1000, treasury, airdropOwner);
        ERC20Airdroper newAirdroper = new ERC20Airdroper();
        newAirdroper.initialize(initData);
    }

    function testDeployManagerDoesNotSupportInterface() public {
        // Should revert with supports = false
        mockDeployManager.setSupports(false);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), 1000, treasury, airdropOwner);
        ERC20Airdroper newAirdroper = new ERC20Airdroper();
        vm.expectRevert();
        newAirdroper.initialize(initData);
    }

    function testReconnectDeployManager() public {
        // Simulate disconnect and reconnect
        mockDeployManager.setSupports(true);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), 1000, treasury, airdropOwner);
        ERC20Airdroper newAirdroper = new ERC20Airdroper();
        newAirdroper.initialize(initData);
        // Try to re-initialize (should revert)
        vm.expectRevert();
        newAirdroper.initialize(initData);
    }

    function testAirdropSuccess() public {
        vm.prank(airdropOwner);
        token.approve(address(airdroper), 600);
        vm.prank(airdropOwner);
        airdroper.airdrop(receivers, amounts);
        assertEq(token.balanceOf(receivers[0]), 100, "Receiver 0 should get 100");
        assertEq(token.balanceOf(receivers[1]), 200, "Receiver 1 should get 200");
        assertEq(token.balanceOf(receivers[2]), 300, "Receiver 2 should get 300");
    }

    function testAirdropBatchSizeExceeded() public {
        address[] memory bigReceivers = new address[](301);
        uint256[] memory bigAmounts = new uint256[](301);
        for (uint256 i = 0; i < 301; i++) {
            bigReceivers[i] = address(uint160(i + 10));
            bigAmounts[i] = 1;
        }
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(bigReceivers, bigAmounts);
    }

    function testAirdropArraysLengthMismatch() public {
        address[] memory badReceivers = new address[](2);
        uint256[] memory badAmounts = new uint256[](3);
        badReceivers[0] = address(0x1);
        badReceivers[1] = address(0x2);
        badAmounts[0] = 1;
        badAmounts[1] = 2;
        badAmounts[2] = 3;
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(badReceivers, badAmounts);
    }

    function testAirdropNotEnoughApprovedTokens() public {
        vm.prank(treasury);
        token.approve(address(airdroper), 10);
        vm.prank(airdropOwner);
        vm.expectRevert();
        airdroper.airdrop(receivers, amounts);
    }

    function testGetInitData() public {
        bytes memory data = airdroper.getInitData(address(0xDEAD), address(token), 1000, treasury, airdropOwner);
        (address d, address t, uint256 a, address tr, address o) =
            abi.decode(data, (address, address, uint256, address, address));
        assertEq(d, address(0xDEAD));
        assertEq(t, address(token));
        assertEq(a, 1000);
        assertEq(tr, treasury);
        assertEq(o, airdropOwner);
    }

    function encodeInitData(address _deployManager, address _token, uint256 _amount, address _treasury, address _owner)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _amount, _treasury, _owner);
    }

    function testDeployViaDeployManager() public {
        vm.prank(managerOwner);
        DeployManager deployManager = new DeployManager();
        ERC20Airdroper template = new ERC20Airdroper();
        vm.prank(managerOwner);
        deployManager.addNewContract(address(template), 0.5 ether, true);
        bytes memory initData = encodeInitData(address(deployManager), address(token), 1000, treasury, airdropOwner);
        vm.deal(address(this), 1 ether);
        uint256 ownerBalanceBefore = managerOwner.balance;
        address deployed = deployManager.deploy{value: 0.5 ether}(address(template), initData);
        uint256 ownerBalanceAfter = managerOwner.balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.5 ether, "Owner should receive the fee");
        ERC20Airdroper deployedAirdroper = ERC20Airdroper(deployed);
        assertEq(address(deployedAirdroper.token()), address(token));
        assertEq(deployedAirdroper.amount(), 1000);
        assertEq(deployedAirdroper.treasury(), treasury);
        assertEq(deployedAirdroper.owner(), airdropOwner);
    }

    function testTemplateIsNotInitialized() public {
        // Ensure the template is never initialized before cloning
        ERC20Airdroper template = new ERC20Airdroper();
        assertFalse(template.initialized(), "Template should not be initialized");
    }

    function testDeployManagerSupportsInterfaceDirect() public {
        DeployManager deployManager = new DeployManager();
        bytes4 iface = type(IDeployManager).interfaceId;
        bool result = deployManager.supportsInterface(iface);
        assertTrue(result, "DeployManager should support IDeployManager interface");
    }

    function testLogInterfaceId() public {
        bytes4 iface = type(IDeployManager).interfaceId;
        emit log_bytes32(bytes32(iface));
        DeployManager deployManager = new DeployManager();
        bool result = deployManager.supportsInterface(iface);
        emit log_named_uint("supportsInterface result", result ? 1 : 0);
    }

    function testSupportsInterfaceOnDeployManager() public {
        DeployManager deployManager = new DeployManager();
        bytes4 iface = type(IDeployManager).interfaceId;
        assertTrue(deployManager.supportsInterface(iface), "Should support IDeployManager");
    }
}
