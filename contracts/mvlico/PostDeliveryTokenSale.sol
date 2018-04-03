pragma solidity ^0.4.19;

import "./TimedTokenSale.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract PostDeliveryTokenSale is TimedTokenSale, Ownable {
  using SafeMath for uint256;

  uint256 tokenDeliverTime;

  mapping(address => uint256) public balances;
  address public tokenHolder;

  function PostDeliveryTokenSale(address _tokenHolder) public {
    tokenHolder = _tokenHolder;
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }
}
