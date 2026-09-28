// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../UtilityContract/IUtilityContract.sol";
import "./IDeployManager.sol";

contract DeployManager is IDeployManager, Ownable, ERC165 {

    constructor() Ownable(msg.sender) payable {}

    struct ContractInfo{
        uint256 fee;
        bool isActive;
        uint256 registeredAt;
    }
    mapping(address => address[]) public deployedContracts;
    mapping(address => ContractInfo) public contractsData;

    function deploy(address _utilityContract, bytes calldata _initData) external override payable returns (address) {
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.isActive, ContractNotActive());
        require(info.fee >= msg.value, InsufficientBalance());
        require(info.registeredAt > 0, ContractDoesNotRegistered());

        address clone = Clones.clone(_utilityContract);

        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        payable(owner()).transfer(msg.value);

        deployedContracts[msg.sender].push(clone);

        emit NewDeployment(clone, msg.sender, msg.value, block.timestamp);

        return clone;
    }


    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external override onlyOwner{
        require(IUtilityContract(_contractAddress).supportsInterface(type(IUtilityContract).interfaceId), ContractIsNotUtilityContract());

        contractsData[_contractAddress] = ContractInfo({
            fee: _fee,
            isActive: _isActive,
            registeredAt: block.timestamp
             });

        emit NewContractAdded(_contractAddress, _fee, _isActive, block.timestamp);
    }

    function updateFee(address _contractAddress, uint256 _newFee) external override onlyOwner{
        require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());
        uint256 oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(_contractAddress, oldFee, _newFee, block.timestamp);
    }

    function deactivateContract(address _contractAddress) external override onlyOwner {
    require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());
    contractsData[_contractAddress].isActive = false;

     emit ContractStatusUpdated(_contractAddress, false, block.timestamp);
    }

    function activateContract(address _contractAddress) external override onlyOwner {
    require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());
    contractsData[_contractAddress].isActive = true;

     emit ContractStatusUpdated(_contractAddress, true, block.timestamp);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool){
        return
            interfaceId == type(IDeployManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
