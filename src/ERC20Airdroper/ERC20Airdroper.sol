// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../UtilityContract/AbstractUtilityContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20Airdroper - Airdrop utility contract for ERC20 tokens
/// @notice This contract allows the owner to airdrop ERC20 tokens to multiple addresses
/// @dev Inherits from AbstractUtilityContract and Ownable
contract ERC20Airdroper is AbstractUtilityContract, Ownable {
    /// @notice Initializes the owner of the implementation contract
    /// @dev The deployer becomes the initial owner of this implementation
    constructor() payable Ownable(msg.sender) {}

    /// @notice Maximum number of recipients allowed in a single airdrop
    uint256 public constant MAX_AIRDROP_BATCH_SIZE = 300;

    /// @notice ERC20 token used for the airdrop
    IERC20 public token;

    /// @notice Configured token amount stored during initialization
    uint256 public amount;

    /// @notice Address from which the tokens are transferred
    address public treasury;

    /// @dev Reverts if receivers and amounts array lengths mismatch
    error ArraysLengthMismatch();

    /// @dev Reverts if insufficient token allowance from treasury
    error NotEnoughApprovedTokens();

    /// @dev Reverts if ERC20 transfer fails
    error TransferFailed();

    /// @dev Reverts if batch size exceeds limit
    error BatchSizeExceeded();

    /// @notice Distributes ERC20 tokens from treasury to recipients
    /// @param receivers Addresses to receive tokens
    /// @param amounts Amount of tokens to send per recipient
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(receivers.length <= MAX_AIRDROP_BATCH_SIZE, BatchSizeExceeded());
        require(receivers.length == amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnoughApprovedTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < receivers.length;) {
            require(token.transferFrom(treasuryAddress, receivers[i], amounts[i]), TransferFailed());
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUtilityContract
    /// @notice Initializes the airdropper contract with required config
    /// @param _initData Encoded deployManager, token, amount, treasury and new owner
    /// @return success True if initialized
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _token, uint256 _amount, address _treasury, address _owner) =
            abi.decode(_initData, (address, address, uint256, address, address));

        setDeployManager(_deployManager);

        token = IERC20(_token);
        amount = _amount;
        treasury = _treasury;

        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @notice Helper to encode constructor-style init data
    /// @param _deployManager Address of the DeployManager
    /// @param _token Address of ERC20 token contract
    /// @param _amount Amount used to validate allowance
    /// @param _treasury Address holding the tokens
    /// @param _owner New owner of the contract
    /// @return bytes Encoded initialization bytes
    function getInitData(address _deployManager, address _token, uint256 _amount, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _amount, _treasury, _owner);
    }
}