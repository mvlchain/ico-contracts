pragma solidity ^0.4.19;

import './FinalizableTokenSale.sol';
import './RefundVault.sol';

contract RefundableTokenSale is FinalizableTokenSale {
  using SafeMath for uint256;

  // refund vault used to hold funds while token sale is ongoing (scattered)
  RefundVault[] vaults;

  event VaultCreated(address walletAddress, address vaultAddress);
  enum State { Running, Succeeded, Failed }
  State public state;

  function RefundableTokenSale(address[] walletAddresses) public {
    state = State.Running;
    vaults = new RefundVault[](walletAddresses.length);
    for (uint i = 0; i < walletAddresses.length; i++) {
      address walletAddress = walletAddresses[i];
      vaults[i] = new RefundVault(walletAddress);
      address vaultAddress = address(vaults[i]);
      VaultCreated(walletAddresses[i], vaultAddress);
    }
  }

  function setState(bool success) public onlyOwner {
    require(state == State.Running);
    state = success ? State.Succeeded : State.Failed;
  }

  function finalization() internal {
    require(state != State.Running);
    if (state == State.Succeeded) {
      close();
    }
  }

  function refund(address investor) public onlyOwner {
    for (uint i = 0; i < vaults.length; i++) {
      RefundVault vault = vaults[i];
      vault.refund(investor); // only one of these vaults refund money
    }
  }

  function enableRefunds() public onlyOwner {
    require(state == State.Failed);
    for (uint i = 0; i < vaults.length; i++) {
      RefundVault vault = vaults[i];
      vault.enableRefunds();
    }
  }

  function refundAll() public onlyOwner {
    require(state == State.Failed);
    for (uint i = 0; i < vaults.length; i++) {
      RefundVault vault = vaults[i];
      vault.refundAll();
    }
  }

  function close() public onlyOwner {
    require(state == State.Succeeded);
    for (uint i = 0; i < vaults.length; i++) {
      RefundVault vault = vaults[i];
      vault.close();
    }
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    // set vault index by mod operator
    uint256 indx = uint256(msg.sender) % vaults.length;
    RefundVault vault = vaults[indx];
    vault.deposit.value(msg.value)(msg.sender);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(state == State.Running);
  }
}