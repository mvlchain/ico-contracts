pragma solidity ^0.4.19;

import './SafeMath.sol';
import './CappedTokenSale.sol';
import "./LimitedTokenSale.sol";
import "./RefundableTokenSale.sol";

contract MVLMainsale is LimitedTokenSale, RefundableTokenSale, CappedTokenSale {
  using SafeMath for uint256;
  mapping(address => uint256) public balances;
  address public tokenHolder;
  uint256 public openingTime;
  uint256 public closingTime;
  uint256 public bonusTime;
  uint256 public timedBonusPercent;
  uint256 public defaultBonusPercent;

  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

  function MVLMainsale(
    address[] walletAddresses, uint256 _openingTime, uint256 _closingTime, uint256 _bonusTime,
    uint256 _timedBonusPercent, uint256 _defaultBonusPercent, uint256 min, uint256 max, uint256 _cap, uint256 _rate,
    address _wallet, DetailedERC20 _token
  )
  CappedTokenSale(_cap)
  LimitedTokenSale(min, max)
  RefundableTokenSale(walletAddresses)
  TokenSale(_rate, _wallet, _token) public {

    require(_closingTime >= _openingTime);
    require(_closingTime >= _bonusTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
    bonusTime = _bonusTime;

    timedBonusPercent = _timedBonusPercent;
    defaultBonusPercent = _defaultBonusPercent;
  }

  function getExchangeRate() internal returns (uint256) {
    if (now < bonusTime) {
      return rate.mul(timedBonusPercent.add(100)).div(100); // r*((100+x) / 100))
    } else {
      return rate.mul(defaultBonusPercent.add(100)).div(100);
    }
  }

  // override _getTokenAmount of TokenSale.sol
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 timedRate = getExchangeRate();
    return _weiAmount.mul(timedRate);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}
