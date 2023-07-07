// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import 'forge-std/Test.sol';
import {AaveV3Ethereum, AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {ProtocolV3TestBase, InterestStrategyValues, ReserveConfig} from 'aave-helpers/ProtocolV3TestBase.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovHelpers} from 'aave-helpers/GovHelpers.sol';
import {AaveV3ListGhoStewardsPayload, Create2Helpers} from './AaveV3ListGhoStewards_20230507_Payload.sol';
import {IGhoSteward} from 'gho-core/contracts/misc/interfaces/IGhoSteward.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';

import {IGhoDiscountRateStrategy} from 'gho-core/contracts/facilitators/aave/interestStrategy/interfaces/IGhoDiscountRateStrategy.sol';
import {GhoInterestRateStrategy} from 'gho-core/contracts/facilitators/aave/interestStrategy/GhoInterestRateStrategy.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

contract AaveV3ListGhoStewards_20230507_Payload_Test is ProtocolV3TestBase {
  AaveV3ListGhoStewardsPayload public proposalPayload;
  address public constant GHO_TOKEN = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  address public constant RISK_COUNCIL = 0x47c71dFEB55Ebaa431Ae3fbF99Ea50e0D3d30fA8;
  address public constant GHO_IR_STRATEGY = 0x16E77D8a7192b65fEd49B3374417885Ff4421A74;
  bytes public GHO_STEWARD_BYTECODE;
  address public GHO_STEWARD;

  function setUp() public {
    vm.createSelectFork('https://rpc.tenderly.co/fork/4aa4b542-16b5-4fb7-8f75-fc1a0e2e3848');
    proposalPayload = new AaveV3ListGhoStewardsPayload();

    GHO_STEWARD_BYTECODE = Create2Helpers.getBytecode(
      address(AaveV3Ethereum.POOL_ADDRESSES_PROVIDER),
      GHO_TOKEN,
      RISK_COUNCIL,
      AaveGovernanceV2.SHORT_EXECUTOR
    );

    GHO_STEWARD = Create2Helpers.getAddress(GHO_STEWARD_BYTECODE);
  }

  function testGhoStewardRoles() public {
    bool beforeGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(address(GHO_STEWARD));
    assertEq(false, beforeGhoStewardAdmin);

    IGhoToken iGhoToken = IGhoToken(GHO_TOKEN);

    bool beforeHasBucketManagerRole = iGhoToken.hasRole(
      iGhoToken.BUCKET_MANAGER_ROLE(),
      address(GHO_STEWARD)
    );

    assertEq(false, beforeHasBucketManagerRole);

    GovHelpers.executePayload(vm, address(proposalPayload), AaveGovernanceV2.SHORT_EXECUTOR);

    bool afterGhoStewardAdmin = AaveV3Ethereum.ACL_MANAGER.isPoolAdmin(address(GHO_STEWARD));
    assertEq(true, afterGhoStewardAdmin);

    bool afterHasBucketManagerRole = iGhoToken.hasRole(
      iGhoToken.BUCKET_MANAGER_ROLE(),
      address(GHO_STEWARD)
    );

    assertEq(true, afterHasBucketManagerRole);
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
}
