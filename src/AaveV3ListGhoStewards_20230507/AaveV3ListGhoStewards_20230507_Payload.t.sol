// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import 'forge-std/console.sol';
import 'forge-std/Test.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {GhoAaveV3GhoSteward} from './AaveV3ListGhoStewards_20230507_Payload.sol';
import {IGhoSteward} from 'gho-core/contracts/misc/interfaces/IGhoSteward.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';

import {IGhoDiscountRateStrategy} from 'gho-core/contracts/facilitators/aave/interestStrategy/interfaces/IGhoDiscountRateStrategy.sol';
import {GhoInterestRateStrategy} from 'gho-core/contracts/facilitators/aave/interestStrategy/GhoInterestRateStrategy.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

contract AaveV3ListGhoStewards_20230507_Payload_Test is ProtocolV3TestBase, GhoAaveV3GhoSteward {
  GhoAaveV3GhoSteward public proposalPayload;
  address immutable ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

  function setUp() public {
    vm.createSelectFork('https://rpc.tenderly.co/fork/4aa4b542-16b5-4fb7-8f75-fc1a0e2e3848');
    proposalPayload = new GhoAaveV3GhoSteward();
  }

  function testGhoStewardRoles() public {
    bool beforeGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(address(GHO_STEWARD));
    assertFalse(beforeGhoStewardAdmin);

    IGhoToken iGhoToken = IGhoToken(GHO_TOKEN);

    bool beforeHasBucketManagerRole = iGhoToken.hasRole(
      iGhoToken.BUCKET_MANAGER_ROLE(),
      address(GHO_STEWARD)
    );

    assertFalse(beforeHasBucketManagerRole);

    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    bool afterGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(address(GHO_STEWARD));
    assertTrue(afterGhoStewardAdmin);

    bool afterHasBucketManagerRole = iGhoToken.hasRole(
      iGhoToken.BUCKET_MANAGER_ROLE(),
      address(GHO_STEWARD)
    );

    assertTrue(afterHasBucketManagerRole);
  }

  function testUpdateBorrowRates() public {
    vm.startPrank(address(RISK_COUNCIL));
    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    IPoolDataProvider iPoolDataProvider = IPoolDataProvider(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER
    );

    IGhoSteward ghoSteward = IGhoSteward(GHO_STEWARD);

    address oldInterestStrategy = iPoolDataProvider.getInterestRateStrategyAddress(
      address(GHO_TOKEN)
    );

    uint256 oldBorrowRate = GhoInterestRateStrategy(oldInterestStrategy)
      .getBaseVariableBorrowRate();

    uint256 newBorrowRate = oldBorrowRate + 15;

    ghoSteward.updateBorrowRate(newBorrowRate);

    address newInterestStrategy = iPoolDataProvider.getInterestRateStrategyAddress(
      address(GHO_TOKEN)
    );
    assertEq(
      GhoInterestRateStrategy(newInterestStrategy).getBaseVariableBorrowRate(),
      newBorrowRate
    );
    vm.stopPrank();
  }

  function testUpdateBorrowRatesWhenNotRiskCouncil() public {
    vm.startPrank(ZERO_ADDRESS);
    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    IPoolDataProvider iPoolDataProvider = IPoolDataProvider(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER
    );

    IGhoSteward ghoSteward = IGhoSteward(GHO_STEWARD);

    address oldInterestStrategy = iPoolDataProvider.getInterestRateStrategyAddress(
      address(GHO_TOKEN)
    );

    uint256 oldBorrowRate = GhoInterestRateStrategy(oldInterestStrategy)
      .getBaseVariableBorrowRate();

    uint256 newBorrowRate = oldBorrowRate + 15;
    vm.expectRevert('INVALID_CALLER');

    ghoSteward.updateBorrowRate(newBorrowRate);
    vm.stopPrank();
  }

  function testUpdateBucketCapacity() public {
    vm.startPrank(RISK_COUNCIL);

    IPoolDataProvider iPoolDataProvider = IPoolDataProvider(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER
    );

    (address GHO_ATOKEN, , ) = iPoolDataProvider.getReserveTokensAddresses(address(GHO_TOKEN));

    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    IGhoToken iGhoToken = IGhoToken(address(GHO_TOKEN));
    IGhoSteward ghoSteward = IGhoSteward(GHO_STEWARD);

    (uint256 oldBucketCapacity, ) = iGhoToken.getFacilitatorBucket(address(GHO_ATOKEN));

    uint128 newBucketCapacity = uint128(oldBucketCapacity) + 1;

    vm.warp(ghoSteward.MINIMUM_DELAY() + 1);
    ghoSteward.updateBucketCapacity(newBucketCapacity);

    (uint256 capacity, ) = iGhoToken.getFacilitatorBucket(address(GHO_ATOKEN));

    assertEq(capacity, newBucketCapacity);
    vm.stopPrank();
  }

  function testUpdateBucketCapacityWhenNotRiskCouncil() public {
    vm.startPrank(ZERO_ADDRESS);

    IPoolDataProvider iPoolDataProvider = IPoolDataProvider(
      AaveV3Ethereum.AAVE_PROTOCOL_DATA_PROVIDER
    );
    (address GHO_ATOKEN, , ) = iPoolDataProvider.getReserveTokensAddresses(address(GHO_TOKEN));

    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    IGhoToken iGhoToken = IGhoToken(address(GHO_TOKEN));
    IGhoSteward ghoSteward = IGhoSteward(GHO_STEWARD);

    (uint256 oldBucketCapacity, ) = iGhoToken.getFacilitatorBucket(address(GHO_ATOKEN));

    uint128 newBucketCapacity = uint128(oldBucketCapacity) + 1;
    vm.warp(ghoSteward.MINIMUM_DELAY() + 1);
    vm.expectRevert('INVALID_CALLER');
    ghoSteward.updateBucketCapacity(newBucketCapacity);
    vm.stopPrank();
  }
}
