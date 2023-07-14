// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {IGhoToken} from 'gho-core/contracts/gho/interfaces/IGhoToken.sol';

/**
 * @title Gho Stop
 * @author AaveCompanies
 * @dev This proposal stops minting of GHO, by setting the capacity of facilitators to zero.
 */
contract GhoAaveV3Stop_20230514_Payload is IProposalGenericExecutor {
  address public constant GHO_TOKEN = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
  address public constant GHO_ATOKEN = 0x00907f9921424583e7ffBfEdf84F92B7B2Be4977;
  address public constant GHO_FLASHMINTER = 0xb639D208Bcf0589D54FaC24E655C79EC529762B8;

  function execute() external override {
    IGhoToken ghoToken = IGhoToken(GHO_TOKEN);
    ghoToken.setFacilitatorBucketCapacity(GHO_ATOKEN, 0);
    ghoToken.setFacilitatorBucketCapacity(GHO_FLASHMINTER, 0);
  }
}
