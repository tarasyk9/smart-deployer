// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../IUtilityContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Airdroper is IUtilityContract, Ownable {
    constructor() Ownable(msg.sender) {}

    IERC20 public token;
    uint256 public amount;
    address public treasury;

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NotEnoughApprovedTokens();
    error TransferFailed();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    bool private initialized;

    function airdrop(address[] calldata _receivers, uint256[] calldata _amounts) external onlyOwner {
        require(_receivers.length == _amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnoughApprovedTokens());

        for (uint256 i = 0; i < _receivers.length; i++) {
            require(token.transferFrom(treasury, _receivers[i], _amounts[i]), TransferFailed());
        }
    }

    function initialize(bytes memory _initData) external returns (bool) {
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
