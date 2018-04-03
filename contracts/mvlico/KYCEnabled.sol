pragma solidity ^0.4.19;

import "./Ownable.sol";
import "./LimitedTokenSale.sol";
import "./RefundableTokenSale.sol";
import "./PostDeliveryTokenSale.sol";

contract KYCEnabled is Ownable {
  enum KYCStatus { Pending, Passed, Rejected }

  mapping(address => KYCStatus) kycStatuses;

  event UpdateKYCStatus(address beneficiary, bool passed);
  event CheckKYCStatus(address beneficiary);

  function updateKYCStatus(address beneficiary, bool passed) public onlyOwner {
    kycStatuses[beneficiary] = passed ? KYCStatus.Passed : KYCStatus.Rejected;
    UpdateKYCStatus(beneficiary, passed);
  }

  modifier onlyKYCPassed(address beneficiary) {
    CheckKYCStatus(beneficiary);
    require(kycStatuses[beneficiary] == KYCStatus.Passed);
    _;
  }
}

contract KYCEnabledTokenSale is PostDeliveryTokenSale, KYCEnabled, LimitedTokenSale, RefundableTokenSale {
  function refund(address investor) public onlyOwner {
    KYCStatus kycStatus = kycStatuses[investor];
    require(state == State.Failed || kycStatus == KYCStatus.Rejected);
    contributions[investor] = 0;
    balances[investor] = 0;
    super.refund(investor);
  }
}
