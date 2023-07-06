// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import 'forge-std/console.sol';
import {AaveV3Ethereum, IACLManager} from 'aave-address-book/AaveV3Ethereum.sol';

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GhoSteward} from 'gho-core/contracts/misc/GhoSteward.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';

/**
 * @title This proposal deploys GhoStewards
 * @author @aave - Aave Co
 */

library Create2Helpers {
  bytes32 public constant CREATE2_SALT = bytes32(0);
  // Declare event for logging deployed contract addresses
  event GhoStewardDeployed(address addr);

  function deployGhoSteward(
    address poolAddressProvider,
    address ghoToken,
    address riskCouncil,
    address shortExecutor
  ) external returns (address) {
    // Compute the bytecode for the new contract

    GhoSteward _ghoStewardContract = new GhoSteward{salt: CREATE2_SALT}(
      poolAddressProvider,
      ghoToken,
      riskCouncil,
      shortExecutor
    );

    // Emit the event with the new contract's address
    emit GhoStewardDeployed(address(_ghoStewardContract));
    return address(_ghoStewardContract); // return the address
  }

  // get the computed address before the contract DeployWithCreate2 deployed using Bytecode of contract DeployWithCreate2 and salt specified by the sender
  function getAddress(bytes memory bytecode) public view returns (address) {
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(this), CREATE2_SALT, keccak256(bytecode))
    );
    return address(uint160(uint256(hash)));
  }

  function getBytecode(
    address poolAddressProvider,
    address ghoToken,
    address riskCouncil,
    address shortExecutor
  ) public pure returns (bytes memory) {
    bytes memory bytecode = type(GhoSteward).creationCode;
    return
      abi.encodePacked(
        bytecode,
        abi.encode(poolAddressProvider, ghoToken, riskCouncil, shortExecutor)
      );
  }
}

contract AaveV3ListGhoStewardsPayload is IProposalGenericExecutor {
  event GhoStewardDeployed(address ghoSteward);

  bytes public GHO_STEWARD_BYTECODE;
  address public immutable GHO_STEWARD;

  // only constants or immutables in the AIP because these are written in bytecode
  // executing contracts via delegateCall() which uses context of contract calling that with short executor
  //  only use constants or immutables

  constructor() {
    GHO_STEWARD_BYTECODE = Create2Helpers.getBytecode(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );

    GHO_STEWARD = Create2Helpers.getAddress(GHO_STEWARD_BYTECODE);
  }

  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;
  //[[0x6A44dfA9277837BC910CeDa563389cDeB5F76855]
  // [0x5d49dBcdd300aECc2C311cFB56593E71c445d60d]]

  address public constant GHO_TOKEN = 0xabf1A66556dD506ea2573bbEa2D9D4baf3c31f09;

  // TODO New address
  // address public constant GHO_TOKEN = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

  function execute() external override {
    // ------------------------------------------------
    // 1. Deployment of GhoSteward
    // ------------------------------------------------

    address deployedGhoSteward = Create2Helpers.deployGhoSteward(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );

    console.log('GHO_STEWARD', GHO_STEWARD);
    console.log('ghoStewardAddress', deployedGhoSteward);

    // ------------------------------------------------
    // 2. Set roles of PoolAdmin and BucketManager to GhoSteward
    // ------------------------------------------------
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(deployedGhoSteward));

    IGhoToken ghoToken = IGhoToken(GHO_TOKEN);

    ghoToken.grantRole(ghoToken.FACILITATOR_MANAGER_ROLE(), address(deployedGhoSteward));
  }
}
