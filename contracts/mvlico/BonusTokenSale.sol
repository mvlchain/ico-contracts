pragma solidity ^0.4.19;

import './Ownable.sol';
import './TokenSale.sol';
import './SafeMath.sol';

contract BonusTokenSale is TokenSale, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) exchangeRates;
  uint256 defaultRate;

  function BonusTokenSale(uint256 _defaultRate) public {
    defaultRate = _defaultRate;
  }

  function setExchangeRate(address investor, uint256 rate) onlyOwner public {
    require(rate > 1);
    exchangeRates[investor] = rate;
  }

  function getExchangeRate(address investor) internal returns (uint256) {
    uint256 exchangeRate = exchangeRates[investor];
    if (exchangeRate == 0) {
      return defaultRate;
    }
    return exchangeRate;
  }

  // override _getTokenAmount of TokenSale.sol
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 rate = getExchangeRate(msg.sender);
    return _weiAmount.mul(rate);
  }
}
