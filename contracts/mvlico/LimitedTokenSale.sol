pragma solidity ^0.4.19;

import "./SafeMath.sol";
import "./TokenSale.sol";
import "./Ownable.sol";


/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with per-user caps.
 */
contract LimitedTokenSale is TokenSale, Ownable {
  using SafeMath for uint256;

  uint256 public minLimit = 100 finney; // minimum contrib = 0.1 ether
  uint256 public maxLimit = 100 ether;

  mapping(address => uint256) public contributions;

  function LimitedTokenSale(uint256 min, uint256 max) public {
    require(min < max);
    minLimit = min;
    maxLimit = max;
  }

  /**
   * @dev Returns the amount contributed so far by a specific user.
   * @param _beneficiary Address of contributor
   * @return User contribution so far
   */
  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the user's funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 targetContrib = contributions[_beneficiary].add(_weiAmount);
    require(targetContrib >= minLimit && targetContrib <= maxLimit);
  }

  /**
   * @dev Extend parent behavior to update user contributions
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }
}
