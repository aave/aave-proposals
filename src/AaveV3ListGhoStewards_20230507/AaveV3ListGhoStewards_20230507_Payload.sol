// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV3Ethereum, IACLManager} from 'aave-address-book/AaveV3Ethereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GhoSteward} from 'gho-core/contracts/misc/GhoSteward.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

/**
 * @title Gho Stewards AIP
 * @author @aave - AaveCompanies
 * @dev This proposal enables GhoSteward for agile parameter changes in GHO. It consists of a set of actions:
 * - Deployment of GhoSteward and transfers ownership to Aave DAO (short executor)
 * - Grants role of PoolAdmin to GhoSteward
 * - Grants role of BucketManager to GhoSteward
 * Relevant governance links:
 * - Governance: https://governance.aave.com/t/arfc-gho-steward-agile-parameter-changes/13922
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x67fa551993a94b801018d02154f3d4f27e29bea51fe6e862686de6bf9ee650af
 */
contract GhoAaveV3GhoSteward is IProposalGenericExecutor {
  event GhoStewardDeployed(address ghoSteward);

  error DeployedGhoStewardNotEqualPrecomuted(string message);

  address public immutable GHO_STEWARD;
  bytes32 public constant CREATE2_SALT = bytes32(0);

  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;
  address public constant GHO_TOKEN = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

  constructor() {
    GHO_STEWARD = getAddress(
      getBytecode(
        address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
        GHO_TOKEN,
        RISK_COUNCIL,
        AaveGovernanceV2.SHORT_EXECUTOR
      )
    );
  }

  function execute() external override {
    // ------------------------------------------------
    // 1. Deployment of GhoSteward
    // ------------------------------------------------
    address deployedGhoSteward = deployGhoSteward(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );

    if (deployedGhoSteward != GHO_STEWARD) {
      revert DeployedGhoStewardNotEqualPrecomuted('Contract addresses do not match');
    }

    // ------------------------------------------------
    // 2. Set roles of PoolAdmin and BucketManager to GhoSteward
    // ------------------------------------------------
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(deployedGhoSteward);
    IGhoToken iGhoToken = IGhoToken(GHO_TOKEN);
    iGhoToken.grantRole(iGhoToken.BUCKET_MANAGER_ROLE(), deployedGhoSteward);
  }

  function deployGhoSteward(
    address poolAddressProvider,
    address ghoToken,
    address riskCouncil,
    address shortExecutor
  ) internal returns (address) {
    GhoSteward _ghoStewardContract = new GhoSteward{salt: CREATE2_SALT}(
      poolAddressProvider,
      ghoToken,
      riskCouncil,
      shortExecutor
    );
    return address(_ghoStewardContract);
  }

  function getBytecode(
    address poolAddressProvider,
    address ghoToken,
    address riskCouncil,
    address shortExecutor
  ) internal pure returns (bytes memory) {
    bytes memory bytecode = type(GhoSteward).creationCode;
    return
      abi.encodePacked(
        bytecode,
        abi.encode(poolAddressProvider, ghoToken, riskCouncil, shortExecutor)
      );
  }

  function getAddress(bytes memory bytecode) internal pure returns (address) {
    bytes32 hash = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        AaveGovernanceV2.SHORT_EXECUTOR,
        CREATE2_SALT,
        keccak256(bytecode)
      )
    );
    return address(uint160(uint256(hash)));
  }
}
