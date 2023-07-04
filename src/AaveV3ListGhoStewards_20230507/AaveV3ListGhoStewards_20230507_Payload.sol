// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AaveV3Ethereum, IACLManager} from 'aave-address-book/AaveV3Ethereum';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

import {EthereumScript} from 'aave-helpers/ScriptUtils.sol';

contract AaveV3ListGhoStewards is IProposalGenericExecutor {
  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;

    
    
    AaveV3Ethereum.POOL_ADDRESSES_PROVIDER
AaveGovernanceV2.SHORT_EXECUTOR

address public constant GHO_TOKEN = 0xabf1A66556dD506ea2573bbEa2D9D4baf3c31f09;


    // address addressesProvider,
    // address ghoToken,
    // address riskCouncil,
    // address shortExecutor



  //[[0x6A44dfA9277837BC910CeDa563389cDeB5F76855]
  // [0x5d49dBcdd300aECc2C311cFB56593E71c445d60d]]

  function execute() external override {
    // new MainnetPayload();
  }
}

/**
 * @title This proposal add DeFi Saver as a flash borrower on Aave V3 OptimismAaveV3Optimism
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xcebb97fa8e551a79e7aae28a135ec0fd26fcb88e8262375f4b4e81ef7047e665
 * - Discussion: https://governance.aave.com/t/arfc-add-defi-saver-to-flashborrowers-on-aave-v3/12410
 */
