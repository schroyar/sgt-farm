// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RewardsDistributionRecipient.sol";
import "./interfaces/IStakingRewards.sol";

contract SGTStaking is 
    Ownable,
    ReentrancyGuard,
    RewardsDistributionRecipient
{
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    IERC20 public SGTToken;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardsDuration = 7 days;
    uint256 public periodFinish = 0;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint) private _balances;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _stakingToken,
        address _rewardsDistribution
        ) Ownable() {
        SGTToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== MODIFIER ========== */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    /* ========== PUBLIC VIEW FUNCTIONS ========== */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return 0;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime)  * rewardRate * 1e18 ) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return ((_balances[account] * (rewardPerTokenStored - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return (rewardRate * rewardsDuration);
    }
    
    function rewardsToken() external view returns (address) {
        return address(IERC20(SGTToken));
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */
    function stake(uint256 _amount) 
        external
        payable
        nonReentrant
        updateReward(msg.sender) 
    {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        SGTToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) 
        external
        nonReentrant
        updateReward(msg.sender) 
    {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        SGTToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function getReward() 
        external
        nonReentrant
        updateReward(msg.sender) 
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        SGTToken.safeTransfer(msg.sender, reward);
        emit GetReward(msg.sender, reward);
    }

    /* ========== OWNER FUNCTIONS ========== */
    function setRewardDuration(uint _rewardsDuration) 
        external
        onlyOwner
    {
        rewardsDuration = _rewardsDuration;
        emit rewardsDurationUpdated(rewardsDuration);
    }


    /* ========== RESTRICTED FUNCTIONS ========== */
    function notifyRewardAmount(uint256 _amountSGT) 
        external   
        override 
        onlyRewardsDistribution
        updateReward(address(0))
    {
         if (block.timestamp >= periodFinish) {
            rewardRate = _amountSGT / rewardsDuration;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (leftover + _amountSGT) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = rewardsDuration + block.timestamp;
        emit RewardAdded(_amountSGT);
    }

    /* ========== EVENTS ========== */
    event rewardsDurationUpdated(uint256 newDuration);
    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event GetReward(address indexed user, uint256 amount);
    event RewardAdded(uint256 amount);        
}
