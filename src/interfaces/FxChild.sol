/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

// IStateReceiver represents interface to receive state
interface IStateReceiver {
    function onStateReceive(uint256 stateId, bytes calldata data) external;
}

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}
