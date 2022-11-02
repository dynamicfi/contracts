// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking2 is Ownable{
    using SafeMath for uint256;
    uint256 public apy = 1000;
    uint256 constant RATE_PRECISION = 10000;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
    uint256 constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;

    uint256 constant PERIOD_PRECSION = 10000;
    IERC20 public token;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    struct StakeDetail {
        uint256 principal;
        uint256 lastStakeAt;
        uint256 firstStakeAt;
    }

    mapping(address => StakeDetail) public stakers;

    function updateAPY(uint256 _apy) external onlyOwner {
        apy = _apy;
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }

    function getStakeDetail(address _staker)
        public
        view
        returns (
            uint256 principal,
            uint256 lastStakeAt,
            uint256 firstStakeAt
        )
    {
        StakeDetail memory stakeDetail = stakers[_staker];
        return (
            stakeDetail.principal,
            stakeDetail.lastStakeAt,
            stakeDetail.firstStakeAt
        );
    }

    function getInterest(address _staker) public view returns (uint256) {
        StakeDetail memory stakeDetail = stakers[_staker];
        uint256 interest = 0;
        uint256 periods = block
            .timestamp
            .sub(stakeDetail.lastStakeAt)
            .mul(PERIOD_PRECSION)
            .div(ONE_DAY_IN_SECONDS);
        for (uint256 i = 0; i < periods; i++) {
            interest = interest.add(
                stakeDetail.principal.mul(apy).div(RATE_PRECISION).div(
                    PERIOD_PRECSION
                )
            );
        }
        return interest;
    }

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
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
            uint256 periods = block
                .timestamp
                .sub(stakeDetail.lastStakeAt)
                .mul(PERIOD_PRECSION)
                .div(ONE_DAY_IN_SECONDS);
            uint256 interest = 0;
            for (uint256 i = 0; i < periods; i++) {
                interest = interest.add(
                    stakeDetail.principal.mul(apy).div(RATE_PRECISION).div(
                        PERIOD_PRECSION
                    )
                );
            }
            stakeDetail.principal = stakeDetail.principal.add(interest);
            stakeDetail.lastStakeAt = block.timestamp;
        }

        emit Deposit(msg.sender, _stakeAmount);
    }

    function redeem(uint256 _redeemAmount) external {
        StakeDetail storage stakeDetail = stakers[msg.sender];
        require(stakeDetail.firstStakeAt > 0, "Staking2: no stake");
        uint256 periods = block
            .timestamp
            .sub(stakeDetail.lastStakeAt)
            .mul(PERIOD_PRECSION)
            .div(ONE_DAY_IN_SECONDS);
        uint256 interest = 0;
        for (uint256 i = 0; i < periods; i++) {
            interest = interest.add(
                stakeDetail.principal.mul(apy).div(RATE_PRECISION).div(
                    PERIOD_PRECSION
                )
            );
        }
        stakeDetail.principal = stakeDetail.principal.add(interest);
        stakeDetail.lastStakeAt = block.timestamp;
        require(
            stakeDetail.principal >= _redeemAmount,
            "Staking2: redeem amount must be less than principal"
        );
        stakeDetail.principal = stakeDetail.principal.sub(_redeemAmount);
        require(
            token.transfer(msg.sender, _redeemAmount),
            "Staking2: transfer failed"
        );
        emit Redeem(msg.sender, _redeemAmount);
    }
}
