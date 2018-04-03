pragma solidity ^0.4.19;

import './TokenSale.sol';
import './Ownable.sol';

contract FinalizableTokenSale is TokenSale, Ownable {
  bool public isFinalized = false;

  event Finalized();

  function finalize() onlyOwner public {
    require(!isFinalized);

    finalization();
    Finalized();

    isFinalized = true;
  }

  function finalization() internal {
  }
}
