// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IUtilityContract is IERC165{

    error DeployManagerCannotBeZero();
    error NotDeployManager();
    error FailedToSetDeployManager();
    error AlreadyInitialized();

    function initialize(bytes memory) external returns (bool);

    function getDeployManager() external view returns (address);
}
