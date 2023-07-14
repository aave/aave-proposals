// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import 'forge-std/Test.sol';
import {ProtocolV3TestBase} from 'aave-helpers/ProtocolV3TestBase.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GhoAaveV3Stop_20230514_Payload} from './GhoAaveV3Stop_20230514_Payload.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

contract GhoAaveV3Stop_20230514_Payload_Test is ProtocolV3TestBase {
  GhoAaveV3Stop_20230514_Payload public proposalPayload;

  function setUp() public {
    vm.createSelectFork('https://rpc.tenderly.co/fork/7deaf9cf-19d9-41c6-8a13-d1a7f1f88ab1');
    proposalPayload = new GhoAaveV3Stop_20230514_Payload();
  }

  function testGhoStop() public {
    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    IGhoToken ghoToken = IGhoToken(proposalPayload.GHO_TOKEN());
    (uint256 capacity, ) = ghoToken.getFacilitatorBucket(proposalPayload.GHO_ATOKEN());
    assertEq(capacity, 0);
    (capacity, ) = ghoToken.getFacilitatorBucket(proposalPayload.GHO_FLASHMINTER());
    assertEq(capacity, 0);

    vm.prank(proposalPayload.GHO_ATOKEN());
    vm.expectRevert('FACILITATOR_BUCKET_CAPACITY_EXCEEDED');
    ghoToken.mint(address(0xff1), 1);

    vm.prank(proposalPayload.GHO_FLASHMINTER());
    vm.expectRevert('FACILITATOR_BUCKET_CAPACITY_EXCEEDED');
    ghoToken.mint(address(0xff1), 1);
  }
}
