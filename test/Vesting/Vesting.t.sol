// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import {Vesting} from "src/LiniarVesting/Vesting.sol";
import {IVesting} from "src/LiniarVesting/IVesting.sol";
import {ERC20Mock} from "test/ERC20Airdroper/ERC20Mock.sol";
import {MockDeployManager} from "test/DeployManager/MockDeployManager.sol";

contract VestingTest is Test {
    Vesting public vesting;
    ERC20Mock public token;
    MockDeployManager public mockDeployManager;
    address public vestingOwner;
    address public beneficiary;
    address public managerOwner;

    // Event definitions for vm.expectEmit
    event TokensWithdrawn(address indexed to, uint256 amount);
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 creationTime);
    event Claim(address indexed beneficiary, uint256 amount, uint256 timestamp);

    receive() external payable {}

    function setUp() public {
        vestingOwner = vm.addr(1);
        beneficiary = vm.addr(2);
        managerOwner = vm.addr(42);
        token = new ERC20Mock();
        vesting = new Vesting();
        mockDeployManager = new MockDeployManager();
        token.mint(address(vesting), 10000 * 1e18);
        bytes memory initData = encodeInitData(address(mockDeployManager), address(token), vestingOwner);
        vesting.initialize(initData);
    }

    function testStartVestingAndClaim() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        vm.warp(block.timestamp + 3);
        vm.prank(beneficiary);
        vesting.claim();
        assertGt(token.balanceOf(beneficiary), 0, "Beneficiary should have claimed tokens");
    }

    function testVestingCliff() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 10,
            duration: 20,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        vm.warp(block.timestamp + 5);
        vm.prank(beneficiary);
        vm.expectRevert();
        vesting.claim();
    }

    function testVestingCooldown() public {
        uint256 blockTimestamp = block.timestamp;
        uint256 cliff = 1;
        uint256 duration = 10;
        uint256 claimCooldown = 5;
        uint256 startTime = blockTimestamp + 1;

        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: startTime,
            cliff: cliff,
            duration: duration,
            claimCooldown: claimCooldown,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        uint256 afterCliff = startTime + cliff + 1;
        vm.warp(afterCliff);
        vm.prank(beneficiary);
        vesting.claim();

        vm.warp(afterCliff + 1);
        vm.prank(beneficiary);
        vm.expectRevert();
        vesting.claim();

        vm.warp(afterCliff + claimCooldown + 1);
        vm.prank(beneficiary);
        vesting.claim();
        assertGt(token.balanceOf(beneficiary), 0, "Beneficiary should have claimed tokens after cooldown");
    }

    function testVestingMinClaimAmount() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 900 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        vm.warp(block.timestamp + 2);
        vm.prank(beneficiary);
        vm.expectRevert();
        vesting.claim();
    }

    function testTemplateIsNotInitialized() public {
        Vesting template = new Vesting();
        assertFalse(template.initialized(), "Template should not be initialized");
    }

    function encodeInitData(address _deployManager, address _token, address _owner)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _owner);
    }

    function testWithdrawUnallocatedSuccess() public {
        uint256 extra = 500 * 1e18;
        token.mint(address(vesting), extra);
        address receiver = vm.addr(99);
        uint256 before = token.balanceOf(receiver);
        uint256 expected = token.balanceOf(address(vesting)) - vesting.allocatedTokens();
        // Only owner can withdraw
        vm.prank(beneficiary);
        vm.expectRevert();
        vesting.withdrawUnallocated(receiver);
        // Owner withdraws
        vm.prank(vestingOwner);
        vm.expectEmit(true, false, false, true);
        emit TokensWithdrawn(receiver, expected);
        vesting.withdrawUnallocated(receiver);
        // Receiver got the tokens
        assertEq(token.balanceOf(receiver), before + expected, "Receiver should get unallocated tokens");
        // Contract's unallocated balance is now zero
        uint256 allocated = vesting.allocatedTokens();
        uint256 afterContract = token.balanceOf(address(vesting));
        assertEq(afterContract - allocated, 0, "No unallocated tokens should remain");
    }

    function testWithdrawUnallocatedRevertIfNothing() public {
        // Make sure all tokens are allocated
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 10000 * 1e18, // matches contract balance
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        address receiver = vm.addr(99);
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.withdrawUnallocated(receiver);
    }

    function testStartVestingRevertsZeroAddress() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: address(0),
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsZeroAmount() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 0,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsZeroDuration() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 0,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsCooldownLongerThanDuration() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 20,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsStartTimeInPast() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp - 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsInsufficientBalance() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 100000 * 1e18, // more than contract balance
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testStartVestingRevertsAlreadyExist() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        // Try to start again before claimed
        vm.prank(vestingOwner);
        vm.expectRevert();
        vesting.startVesting(params);
    }

    function testGetVestingInfoAndInitData() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        IVesting.VestingInfo memory info = vesting.getVestingInfo(beneficiary);
        assertEq(info.totalAmount, 1000 * 1e18);
        assertEq(info.created, true);
        bytes memory data = vesting.getInitData(address(mockDeployManager), address(token), vestingOwner);
        (address d, address t, address o) = abi.decode(data, (address, address, address));
        assertEq(d, address(mockDeployManager));
        assertEq(t, address(token));
        assertEq(o, vestingOwner);
    }

    function testVestedAndClaimableAmountViews() public {
        IVesting.VestingParams memory params = IVesting.VestingParams({
            beneficiary: beneficiary,
            totalAmount: 1000 * 1e18,
            startTime: block.timestamp + 1,
            cliff: 1,
            duration: 10,
            claimCooldown: 2,
            minClaimAmount: 100 * 1e18
        });
        vm.prank(vestingOwner);
        vesting.startVesting(params);
        // Before cliff
        assertEq(vesting.vestedAmount(beneficiary), 0);
        assertEq(vesting.claimableAmount(beneficiary), 0);
        // After cliff
        vm.warp(block.timestamp + 3);
        assertGt(vesting.vestedAmount(beneficiary), 0);
        assertGt(vesting.claimableAmount(beneficiary), 0);
    }
}