pragma solidity ^0.4.19;

import './SafeMath.sol';
import './Ownable.sol';

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address[] depositedAddresses;

  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   function getDepositedAddresses() view public returns(address[]) {
     return depositedAddresses;
   }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
    depositedAddresses.push(investor);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) onlyOwner public {
    uint256 depositedValue = deposited[investor];
    if (depositedValue > 0) {
      deposited[investor] = 0;
      investor.transfer(depositedValue);
      Refunded(investor, depositedValue);
    }
  }

  function refundAll() onlyOwner public {
    require(state == State.Refunding);
    for (uint i = 0; i < depositedAddresses.length; i++) {
      refund(depositedAddresses[i]);
    }
  }
}
