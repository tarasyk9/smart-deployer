// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import "./IDeployManager.sol";

/// @title DeployManager - Factory for utility contracts
/// @notice Allows users to deploy utility contracts by cloning registered templates.
/// @dev Uses OpenZeppelin's Clones and Ownable; assumes templates implement IUtilityContract.
contract DeployManager is IDeployManager, Ownable, ERC165 {
    constructor() payable Ownable(msg.sender) {}

    /// @dev Stores registered contracts information
    struct ContractInfo {
        uint256 fee; /// @notice Deployment fee (in wei)
        bool isDeployable; /// @notice Shows deployable status
        uint256 registeredAt; /// @notice registration timestamp
    }

    /// @dev Maps deployer address to an array of deployed contracts addresses
    mapping(address => address[]) public deployedContracts;

    /// @dev Maps registered contract address to it's registration data
    mapping(address => ContractInfo) public contractsData;

    /// @inheritdoc IDeployManager
    function deploy(address _utilityContract, bytes calldata _initData) external payable override returns (address) {
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.isDeployable, ContractNotActive());
        require(msg.value >= info.fee, NotEnoughtFunds());
        require(info.registeredAt > 0, ContractDoesNotRegistered());

        address clone = Clones.clone(_utilityContract);


        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        deployedContracts[msg.sender].push(clone);

        payable(owner()).transfer(msg.value);

        emit NewDeployment(msg.sender, clone, msg.value, block.timestamp);

        return clone;
    }

    /// @inheritdoc IDeployManager
    function addNewContract(address _contractAddress, uint256 _fee, bool _isDeployable) external override onlyOwner {
        require(
            IUtilityContract(_contractAddress).supportsInterface(type(IUtilityContract).interfaceId),
            ContractIsNotUtilityContract()
        );
        require(contractsData[_contractAddress].registeredAt == 0, AlreadyRegistered());

        contractsData[_contractAddress] = ContractInfo({fee: _fee, isDeployable: _isDeployable, registeredAt: block.timestamp});

        emit NewContractAdded(_contractAddress, _fee, _isDeployable, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function updateFee(address _contractAddress, uint256 _newFee) external override onlyOwner {
        require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());

        uint256 _oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(_contractAddress, _oldFee, _newFee, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function deactivateContract(address _address) external override onlyOwner {
        require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());

        contractsData[_address].isDeployable = false;

        emit ContractStatusUpdated(_address, false, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function activateContract(address _address) external override onlyOwner {
        require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());

        contractsData[_address].isDeployable = true;

        emit ContractStatusUpdated(_address, true, block.timestamp);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IDeployManager).interfaceId || super.supportsInterface(interfaceId);
    }
}