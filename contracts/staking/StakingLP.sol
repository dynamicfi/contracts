// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingLP is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint112;
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter;

    modifier noContract() {
        require(
            tx.origin == msg.sender,
            "StakingLP: Contract not allowed to interact"
        );
        _;
    }

    event Stake(
        address indexed _from,
        uint256 indexed _id,
        uint256 _timestamp,
        uint256 _amount
    );

    event Withdraw(
        address indexed _from,
        uint256 indexed _id,
        uint256 _startTimestamp,
        uint256 _timestamp,
        uint256 _principal,
        uint256 _interest
    );

    event Claim(
        address indexed _from,
        uint256 indexed _id,
        uint256 _timestamp,
        uint256 _interest
    );

    struct StakeDetail {
        address staker;
        uint256 startAt;
        uint256 endAt;
        uint256 principal;
        uint256 interestRate;
        uint256 lastClaimAt;
    }

    mapping(uint256 => StakeDetail) public idToStakeDetail;

    mapping(address => uint256[]) private _addressToIds;
    mapping(uint256 => uint256) public terms;

    address[] internal _addresses;

    bool public enabled;
    uint256 constant MIN_AMOUNT = 1e9;
    uint256 constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * ONE_DAY_IN_SECONDS;
    uint256 constant DENOMINATOR = 10000;

    IPancakeRouter public router;
    IPancakePair public pair;
    IERC20 public rewardToken;

    constructor(
        address _pair,
        address _router,
        address _rewardToken
    ) {
        pair = IPancakePair(_pair);
        router = IPancakeRouter(_router);
        rewardToken = IERC20(_rewardToken);
        enabled = false;

        terms[0] = 3200;
    }

    modifier onlyStakeholder(uint256 _id) {
        StakeDetail memory stakeDetail = idToStakeDetail[_id];
        require(
            stakeDetail.staker == msg.sender,
            "Staking: Caller is not the stakeholder"
        );
        _;
    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function setTerm(uint256 _term, uint256 _interestRate) external onlyOwner {
        require(!enabled, "Staking: Cannot set interest rate while enabled");
        require(
            _interestRate <= 10000,
            "Staking: Interest rate must be less than 100%"
        );
        terms[_term] = _interestRate;
    }

    function stake(uint256 _amount, uint256 _duration) external nonReentrant noContract {
        require(enabled, "Staking: Staking is disabled");
        require(_amount >= 1e18, "Staking: Amount must be >= 1 token");
        require(terms[_duration] > 0, "Staking: Term is not supported");

        uint256 currentId = _tokenIdCounter.current();

        StakeDetail memory newStake = StakeDetail(
            msg.sender,
            block.timestamp,
            block.timestamp.add(_duration),
            _amount,
            terms[_duration],
            block.timestamp
        );
        idToStakeDetail[currentId] = newStake;

        if (_addressToIds[msg.sender].length == 0) {
            _addresses.push(msg.sender);
        }
        _addressToIds[msg.sender].push(currentId);
        pair.transferFrom(msg.sender, address(this), _amount);
        _tokenIdCounter.increment();

        emit Stake(msg.sender, currentId, block.timestamp, _amount);
    }

    function getPairPrice() public view returns (uint256) {
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = pair.getReserves();

        uint256 totalPoolValue = reserve1.mul(2);
        uint256 mintedPair = pair.totalSupply();
        uint256 pairPriceInETH = totalPoolValue.mul(1e18).div(mintedPair);
        // return pairPriceInETH;
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);
        uint256[] memory amounts = router.getAmountsOut(pairPriceInETH, path);
        return amounts[1];
    }

    function getPrincipal(uint256 _id) external view returns (uint256) {
        return idToStakeDetail[_id].principal;
    }

    function getInterest(uint256 _id) public view returns (uint256) {
        StakeDetail memory currentStake = idToStakeDetail[_id];
        uint256 interestRate = currentStake.interestRate;
        uint256 principal = currentStake.principal;
        uint256 startAt = currentStake.startAt;
        uint256 lastClaimAt = currentStake.lastClaimAt;
        uint256 duration = block.timestamp.sub(startAt);
        if (lastClaimAt > 0) {
            duration = block.timestamp.sub(lastClaimAt);
        }
        uint256 interest = principal
            .mul(interestRate)
            .mul(duration)
            .div(ONE_YEAR_IN_SECONDS)
            .div(10000);
        return interest.mul(getPairPrice()).div(1e18);
    }

    function claim(uint256 _id) external onlyStakeholder(_id) nonReentrant noContract {
        uint256 interest = getInterest(_id);
        require(interest > 0, "Staking: No interest to claim");
        StakeDetail storage currentStake = idToStakeDetail[_id];
        currentStake.lastClaimAt = block.timestamp;
        rewardToken.transfer(msg.sender, interest);
        emit Claim(msg.sender, _id, block.timestamp, interest);
    }

    function withdraw(uint256 _id) external onlyStakeholder(_id) nonReentrant noContract {
        StakeDetail memory currentStake = idToStakeDetail[_id];
        require(
            block.timestamp >= currentStake.endAt,
            "Staking: Cannot withdraw before end date"
        );
        uint256 interest = getInterest(_id);
        uint256 principal = currentStake.principal;
        uint256 startTimestamp = currentStake.startAt;

        delete idToStakeDetail[_id];

        for (uint256 i = 0; i < _addressToIds[msg.sender].length; ++i) {
            if (_addressToIds[msg.sender][i] == _id) {
                _addressToIds[msg.sender][i] = _addressToIds[msg.sender][
                    _addressToIds[msg.sender].length - 1
                ];
                _addressToIds[msg.sender].pop();
                break;
            }
        }
        if (_addressToIds[msg.sender].length == 0) {
            for (uint256 i = 0; i < _addresses.length; ++i) {
                if (_addresses[i] == msg.sender) {
                    _addresses[i] = _addresses[_addresses.length - 1];
                    _addresses.pop();
                    break;
                }
            }
        }
        pair.transfer(msg.sender, principal);
        rewardToken.transfer(msg.sender, interest);

        emit Withdraw(
            msg.sender,
            _id,
            startTimestamp,
            block.timestamp,
            principal,
            interest
        );
    }

    function getStakingIds() external view returns (uint256[] memory) {
        return _addressToIds[msg.sender];
    }

    function getStakeHolders()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _addresses;
    }

    function transferStakingToken(address _recipient, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        return pair.transfer(_recipient, _amount);
    }
}
