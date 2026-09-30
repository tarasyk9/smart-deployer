// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {DeployManager} from "src/DeployManager/DeployManager.sol";
import {IDeployManager} from "src/DeployManager/IDeployManager.sol";
import {IUtilityContract} from "src/UtilityContract/IUtilityContract.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract MockUtility is IUtilityContract, ERC165 {
    bool public initialized;
    bytes public lastInitData;

    function initialize(bytes memory data) external override returns (bool) {
        lastInitData = data;
        initialized = true;
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IUtilityContract).interfaceId || super.supportsInterface(interfaceId);
    }

    function getDeployManager() external pure override returns (address) {
        return address(0);
    }
}

contract MockUtilityFailInit is IUtilityContract, ERC165 {
    function initialize(bytes memory) external pure override returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IUtilityContract).interfaceId || super.supportsInterface(interfaceId);
    }

    function getDeployManager() external pure override returns (address) {
        return address(0);
    }
}

contract DeployManagerTest is Test {
    DeployManager public manager;
    MockUtility public mockUtility;
    MockUtilityFailInit public badMockUtility;
    address public owner;
    address public user;

    receive() external payable {}

    function setUp() public {
        owner = vm.addr(1);
        user = vm.addr(2);
        manager = new DeployManager();
        mockUtility = new MockUtility();
        badMockUtility = new MockUtilityFailInit();
    }

    function testAddNewContract() public {
        manager.addNewContract(address(mockUtility), 1 ether, true);
        (uint256 fee, bool isActive, uint256 registeredAt) = manager.contractsData(address(mockUtility));
        assertEq(fee, 1 ether);
        assertTrue(isActive);
        assertGt(registeredAt, 0);
    }

    function testAddNewContractRejectsNonUtility() public {
        vm.expectRevert();
        manager.addNewContract(address(0x1234), 1 ether, true);
    }

    function testDeploy() public {
        manager.addNewContract(address(mockUtility), 0.1 ether, true);
        bytes memory initData = encodeInitData(user, 42);
        vm.deal(user, 1 ether);
        vm.prank(user);
        address deployed = manager.deploy{value: 0.1 ether}(address(mockUtility), initData);
        assertTrue(deployed != address(0));
        assertEq(MockUtility(deployed).initialized(), true);
        assertEq(MockUtility(deployed).lastInitData(), initData);
        assertEq(manager.deployedContracts(user, 0), deployed);
    }

    function testDeployFailsIfInactive() public {
        manager.addNewContract(address(mockUtility), 0.1 ether, false);
        bytes memory initData = encodeInitData(user, 42);
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert();
        manager.deploy{value: 0.1 ether}(address(mockUtility), initData);
    }

    function testDeployFailsIfNotEnoughFunds() public {
        manager.addNewContract(address(mockUtility), 1 ether, true);
        bytes memory initData = encodeInitData(user, 42);
        vm.deal(user, 0.5 ether);
        vm.prank(user);
        vm.expectRevert();
        manager.deploy{value: 0.5 ether}(address(mockUtility), initData);
    }

    function testDeployFailsIfNotRegistered() public {
        bytes memory initData = encodeInitData(user, 42);
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert();
        manager.deploy{value: 0.1 ether}(address(mockUtility), initData);
    }

    function testUpdateFee() public {
        manager.addNewContract(address(mockUtility), 1 ether, true);
        manager.updateFee(address(mockUtility), 2 ether);
        (uint256 fee,,) = manager.contractsData(address(mockUtility));
        assertEq(fee, 2 ether);
    }

    function testDeactivateAndActivateContract() public {
        manager.addNewContract(address(mockUtility), 1 ether, true);
        manager.deactivateContract(address(mockUtility));
        (, bool isActive,) = manager.contractsData(address(mockUtility));
        assertFalse(isActive);
        manager.activateContract(address(mockUtility));
        (, isActive,) = manager.contractsData(address(mockUtility));
        assertTrue(isActive);
    }

    function testSupportsInterface() public {
        assertTrue(manager.supportsInterface(type(IDeployManager).interfaceId));
        assertFalse(manager.supportsInterface(0x12345678));
    }

    function testDeployFailsIfInitializationFails() public {
        manager.addNewContract(address(badMockUtility), 0.1 ether, true);
        bytes memory initData = encodeInitData(user, 42);
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert();
        manager.deploy{value: 0.1 ether}(address(badMockUtility), initData);
    }

    function testUpdateFeeFailsIfNotRegistered() public {
        vm.expectRevert();
        manager.updateFee(address(0x1234), 1 ether);
    }

    function testDeactivateContractFailsIfNotRegistered() public {
        vm.expectRevert();
        manager.deactivateContract(address(0x1234));
    }

    function testActivateContractFailsIfNotRegistered() public {
        vm.expectRevert();
        manager.activateContract(address(0x1234));
    }

    function encodeInitData(address user_, uint256 value_) public pure returns (bytes memory) {
        return abi.encode(user_, value_);
    }
}
