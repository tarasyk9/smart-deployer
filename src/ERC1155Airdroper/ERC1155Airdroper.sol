// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../UtilityContract/AbstractUtilityContract.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC1155Airdroper - Airdrop utility contract for ERC1155 tokens
/// @notice This contract allows the owner to airdrop ERC1155 tokens to multiple addresses
/// @dev Inherits from AbstractUtilityContract and Ownable
contract ERC1155Airdroper is AbstractUtilityContract, Ownable {
    /// @notice Initializes the owner of the implementation contract
    /// @dev The deployer becomes the initial owner of this implementation
    constructor() payable Ownable(msg.sender) {}

    /// @notice Maximum number of recipients allowed in a single airdrop
    uint256 public constant MAX_AIRDROP_BATCH_SIZE = 100;

    /// @notice ERC1155 token used for the airdrop
    IERC1155 public token;

    /// @notice Address from which the tokens are transferred
    address public treasury;

    /// @notice Reverts if the receivers array has an invalid length
    error ReceiversLengthMismatch();

    /// @notice Reverts if the amounts array has an invalid length
    error AmountsLengthMismatch();

    /// @dev Reverts if insufficient token allowance from treasury
    error NeedToApproveTokens();

    /// @dev Reverts if batch size exceeds limit
    error BatchSizeExceeded();

    /// @notice Distributes ERC1155 tokens from treasury to recipients
    /// @param receivers Addresses to receive tokens
    /// @param amounts Amount of tokens to send per recipient
    /// @param tokenIds The ids ERC1155 token
    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        require(tokenIds.length <= MAX_AIRDROP_BATCH_SIZE, BatchSizeExceeded());
        require(receivers.length == tokenIds.length, ReceiversLengthMismatch());
        require(amounts.length == tokenIds.length, AmountsLengthMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < amounts.length;) {
            token.safeTransferFrom(treasuryAddress, receivers[i], tokenIds[i], amounts[i], "");
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
        (address _deployManager, address _token, address _treasury, address _owner) =
            abi.decode(_initData, (address, address, address, address));

        setDeployManager(_deployManager);

        token = IERC1155(_token);
        treasury = _treasury;

        Ownable.transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @notice Helper to encode constructor-style init data
    /// @param _deployManager Address of the DeployManager
    /// @param _token Address of ERC20 token contract
    /// @param _treasury Address holding the tokens
    /// @param _owner New owner of the contract
    /// @return bytes Encoded initialization bytes
    function getInitData(address _deployManager, address _token, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _treasury, _owner);
    }
}
