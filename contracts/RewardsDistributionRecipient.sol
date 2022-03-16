// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract RewardsDistributionRecipient {

    address public rewardsDistribution;

    function notifyRewardAmount(uint256 rewardSGT) external virtual;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

}