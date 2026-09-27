// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../UtilityContract/AbstractUtilityContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Airdroper is AbstractUtilityContract, Ownable {

    constructor() Ownable(msg.sender) payable {}

    IERC20 public token;
    uint256 public amount;
    address public treasury;
    uint256 public constant MAX_AIRDROP_BATCH_SIZE = 10;

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NotEnoughApprovedTokens();
    error TransferFailed();
    error BatchSizeExceeded();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    bool private initialized;

    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length <= MAX_AIRDROP_BATCH_SIZE, BatchSizeExceeded());
        require(receivers.length == amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnoughApprovedTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < receivers.length;) {
            require(token.transferFrom(treasuryAddress, receivers[i], amounts[i]), TransferFailed());
            unchecked{ ++i; }
        }
    }

    function initialize(bytes memory _initData) external override returns (bool) {
        (address _token, uint256 _amount, address _treasury, address _owner) =
            abi.decode(_initData, (address, uint256, address, address));

        token = IERC20(_token);
        treasury = _treasury;
        amount = _amount;

        Ownable._transferOwnership(_owner);

        initialized = true;

        return true;
    }

    function getInitData(address _token, uint256 _amount, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_token, _amount, _treasury, _owner);
    }
}
