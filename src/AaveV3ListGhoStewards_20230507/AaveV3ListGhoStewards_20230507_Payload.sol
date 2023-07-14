// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import 'forge-std/console2.sol';
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
contract AaveV3ListGhoStewardsPayload is IProposalGenericExecutor {
  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;
  address public constant GHO_TOKEN = 0xabf1A66556dD506ea2573bbEa2D9D4baf3c31f09; // TODO
  address public immutable GHO_STEWARD;

  bytes32 constant SALT = bytes32(0);

  constructor() {
    console2.log('params predict');
    console2.log(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );
    console2.log('bytecode');
    console2.logBytes(type(GhoSteward).creationCode);
    GHO_STEWARD = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              AaveGovernanceV2.SHORT_EXECUTOR,
              SALT,
              keccak256(
                abi.encodePacked(
                  type(GhoSteward).creationCode,
                  abi.encodePacked(
                    address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
                    GHO_TOKEN,
                    RISK_COUNCIL,
                    AaveGovernanceV2.SHORT_EXECUTOR
                  )
                )
              )
            )
          )
        )
      )
    );
  }

  function execute() external override {
    // ------------------------------------------------
    // 1. Deployment of GhoSteward
    // ------------------------------------------------

    console2.log('params deploy');
    console2.log(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );
    console2.log('bytecode');
    console2.logBytes(type(GhoSteward).creationCode);
    GhoSteward deployedGhoSteward = new GhoSteward{salt: SALT}(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );

    console2.log('GHO_STEWARD', GHO_STEWARD);
    console2.log('ghoStewardAddress', address(deployedGhoSteward));

    // ------------------------------------------------
    // 2. Set roles of PoolAdmin and BucketManager to GhoSteward
    // ------------------------------------------------
    AaveV3Ethereum.ACL_MANAGER.addPoolAdmin(address(deployedGhoSteward));

    IGhoToken ghoToken = IGhoToken(GHO_TOKEN);
    ghoToken.grantRole(ghoToken.FACILITATOR_MANAGER_ROLE(), address(deployedGhoSteward));
  }
}
