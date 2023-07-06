// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import 'forge-std/Test.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveV3ListGhoStewardsPayload, Create2Helpers} from './AaveV3ListGhoStewards_20230507_Payload.sol';
import {IGhoSteward} from 'gho-core/contracts/misc/interfaces/IGhoSteward.sol';

contract AaveV3ListGhoStewards_20230507_Payload_Test is ProtocolV3TestBase {
  AaveV3ListGhoStewardsPayload public proposalPayload;
  address public constant GHO_TOKEN = 0xabf1A66556dD506ea2573bbEa2D9D4baf3c31f09;
  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;

  function setUp() public {
    vm.createSelectFork('https://rpc.tenderly.co/fork/20ba480b-7e90-4c21-bfe5-bb7677d96c60');
    proposalPayload = new AaveV3ListGhoStewardsPayload();
  }

  function testGhoStewardRoles() public {
    // proposalPayload = new AaveV3ListGhoStewardsPayload();

    console.log('address proposal payload', address(proposalPayload));

    // vm.startPrank(AaveV3Ethereum.ACL_ADMIN);

    bool beforeGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(
      address(0xEee31d22498A65eEBd81694B79F9a6840DacfA27)
    );
    assertEq(false, beforeGhoStewardAdmin);

    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    bool afterGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(
      address(0xEee31d22498A65eEBd81694B79F9a6840DacfA27)
    );

    assertEq(true, afterGhoStewardAdmin);

    console.log('afterGho', afterGhoStewardAdmin);

    // vm.stopPrank();

    // bool afterGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(address(proposalPayload));

    // Risk council call updateBorrowRate and verify its correct
    // IGh

    // console.log('afterGho', afterGhoStewardAdmin);
    // assertEq(true, afterGhoStewardAdmin);

    // IGhoToken ghoToken = IGhoToken(GHO_TOKEN);

    // checks pool admin
    // check for bucket admin

    // gho steward can call functions and update
  }

  //   function testGhoStewardActions() public {
  //     vm.startPrank(address(0xEee31d22498A65eEBd81694B79F9a6840DacfA27));
  //     GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

  //     IGhoSteward ghoSteward = IGhoSteward(0xEee31d22498A65eEBd81694B79F9a6840DacfA27);
  //     assertEq(true, true);
  //     vm.stopPrank();
  //   }
}
