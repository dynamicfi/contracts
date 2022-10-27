// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking2 {
    using SafeMath for uint256;
    uint256 public apr = 1000;
    uint256 constant RATE_PRECISION = 10000;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    struct StakeDetail {
        uint256 principal;
        uint256 interestRate;
        uint256 lastStakeAt;
        uint256 lastCompoundAt;
        uint256 claimedAmount;
        uint256 firstStakeAt;
    }

    mapping(address => StakeDetail) public stakers;

    function deposit(uint256 _stakeAmount) external {
        require(
            _stakeAmount > 0,
            "Staking2: stake amount must be greater than 0"
        );
        token.transferFrom(msg.sender, address(this), _stakeAmount);
        StakeDetail storage stakeDetail = stakers[msg.sender];
        if (stakeDetail.firstStakeAt == 0) {
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
            stakeDetail.lastStakeAt = block.timestamp;
            stakeDetail.firstStakeAt = stakeDetail.firstStakeAt == 0
                ? block.timestamp
                : stakeDetail.firstStakeAt;
        } else {
            stakeDetail.lastStakeAt = block.timestamp;
            /// interest
            uint256 interest = stakeDetail
                .principal
                .mul(apr)
                .mul(block.timestamp.sub(stakeDetail.lastCompoundAt))
                .div(RATE_PRECISION)
                .div(ONE_YEAR_IN_SECONDS);
            stakeDetail.principal = stakeDetail.principal.add(
                interest.add(_stakeAmount)
            );
        }
    }

    function redeem(uint256 _redeemAmount) external {
        StakeDetail storage stakeDetail = stakers[msg.sender];
        require(stakeDetail.firstStakeAt > 0, "Staking2: no stake");
        require(
            stakeDetail.principal >= _redeemAmount,
            "Staking2: redeem amount must be less than principal"
        );
        stakeDetail.principal = stakeDetail.principal.sub(_redeemAmount);
        token.transfer(msg.sender, _redeemAmount);
        uint256 interest = stakeDetail
            .principal
            .mul(apr)
            .mul(block.timestamp.sub(stakeDetail.lastCompoundAt))
            .div(RATE_PRECISION)
            .div(ONE_YEAR_IN_SECONDS);
        stakeDetail.principal = stakeDetail.principal.add(interest);
    }

    function compound() external {
        StakeDetail storage stakeDetail = stakers[msg.sender];
        require(stakeDetail.firstStakeAt > 0, "Staking2: no stake");
        uint256 interest = stakeDetail
            .principal
            .mul(apr)
            .mul(block.timestamp.sub(stakeDetail.lastCompoundAt))
            .div(RATE_PRECISION)
            .div(ONE_YEAR_IN_SECONDS);
        stakeDetail.principal = stakeDetail.principal.add(interest);
        stakeDetail.lastCompoundAt = block.timestamp;
    }
}
