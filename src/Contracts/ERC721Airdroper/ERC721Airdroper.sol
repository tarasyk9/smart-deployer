// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../IUtilityContract.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Airdroper is IUtilityContract, Ownable {
    constructor() Ownable(msg.sender) {}

    IERC721 public token;
    address public treasury;

    error AlreadyInitialized();
    error ArraysLengthMismatch();
    error NeedToAprovedTokens();
    error TransferFailed();

    modifier notInitialized() {
        require(!initialized, AlreadyInitialized());
        _;
    }

    bool private initialized;

    function airdrop(address[] calldata _receivers, uint256[] calldata _tokenId) external onlyOwner {
        require(_receivers.length == _tokenId.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToAprovedTokens());

        for (uint256 i = 0; i < _receivers.length; i++) {
            token.safeTransferFrom(treasury, _receivers[i], _tokenId[i], "");
        }
    }

    function initialize(bytes memory _initData) external returns (bool) {
        (address _token, address _treasury, address _owner) = abi.decode(_initData, (address, address, address));

        token = IERC721(_token);
        treasury = _treasury;

        Ownable._transferOwnership(_owner);

        initialized = true;

        return true;
    }

    function getInitData(address _token, address _treasury, address _owner) external pure returns (bytes memory) {
        return abi.encode(_token, _treasury, _owner);
    }
}
