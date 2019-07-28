pragma solidity >=0.4.4;

import "../Token.sol";
import "../Server.sol";

import "../InvestmentPersistance.sol";
import "../AccountingPersistance.sol";

contract InvestmentService is Binded('InvestmentService'), Token {
  string constant public standard = 'InsuranceToken 0.1';
  string constant public name = 'InsuranceToken';
  string constant public symbol = 'INS';
  uint8 constant public decimals = 0;

  // Expressed in % since you cannot express floats numbers in solidity.
  uint8 constant public holderTokensPct = 10;
  uint256 constant public initialSupply = 1000000;

  bool public mintingAllowed;
  uint256 public allowedMinting;

  event Dividends(uint perToken);
  event TokenOffering(uint tokenAmount, uint tokenPrice);

  function InvestmentService() {
    mintingAllowed = false;
    allowedMinting = 0;
  }

  function bootstrapInvestmentService(uint256 initialTokenPrice) requiresPermission(PermissionLevel.Manager) {
    mintingAllowed = true;
    allowedMinting = initialSupply;
    persistance().setTokenPrice(initialTokenPrice);
    mintTokens(initialSupply);
  }

  function getTotalSupply() constant returns (uint256) {
    return persistance().totalSupply();
  }

  function availableTokenSupply() constant returns (uint256) {
    return persistance().balances(manager);
  }

  function circulatingTokens() constant returns (uint256) {
    return getTotalSupply() - availableTokenSupply();
  }

  function tokenPrice() constant returns (uint256) {
    return persistance().tokenPrice();
  }

  event Log(string debug);
  event Log2(int256 a);

  function performFundAccounting() requiresPermission(PermissionLevel.Manager) {
    Log("starting u know");
    var accounting = AccountingPersistance(addressFor('AccountingDB'));
    var (premiums,claims,) = accounting.accountingPeriods(accounting.currentPeriod());
    var delta = int256(premiums) - int256(claims);
    Log2(delta);

    if (delta > 0) {
      Log("profits");
      sendProfitsToInvestors(uint256(delta));
      //allowedMinting = calculateAllowedMinting();
      if (allowedMinting > 0) {
        mintingAllowed = true;
      }
    }

    //accounting.startNewAccoutingPeriod();
  }

  function calculateAllowedMinting() returns (uint256) {
    var optimalTokens = 0; // calculate with actuarial model
    var delta = int256(optimalTokens) - int256(getTotalSupply());
    return delta > 0 ? uint256(delta) : 0;
  }

  // TODO: Add token mint allowance quotas.
  function mintTokens(uint256 newTokens) {
    if (mintingAllowed && newTokens <= allowedMinting) {
      mintingAllowed = false;
    } else {
      throw;
    }

    uint256 tokensForHolder = (newTokens * holderTokensPct) / 100;
    if (tokensForHolder > newTokens) { // wtf
      throw;
    }

    persistance().setTokenSupply(getTotalSupply() + newTokens);
    persistance().operateBalance(manager, int256(newTokens) - int256(tokensForHolder));
    persistance().operateBalance(Server(manager).owner(), int256(tokensForHolder));

    TokenOffering(availableTokenSupply(), tokenPrice());
  }

  function buyTokens(address holder, uint256 value) requiresPermission(PermissionLevel.Manager) returns (bool) {
    uint256 tokenAmount = value / tokenPrice();
    if (persistance().balances(manager) >= tokenAmount && persistance().balances(holder) + tokenAmount > persistance().balances(holder))  {
      persistance().operateBalance(holder, int256(tokenAmount));
      persistance().operateBalance(manager,int256(-1) * int256(tokenAmount));

      Transfer(this, holder, tokenAmount);
    } else {
      throw;
    }
    return true;
  }

  function withdrawDividendsForHolder(address holder) requiresPermission(PermissionLevel.Manager) {
    if (!Server(manager).sendFunds(holder, persistance().dividends(holder), 'div', true)) {
      throw;
    }

    persistance().operateDividend(holder, 0);
  }

  function sendProfitsToInvestors(uint256 profits) private returns (bool) {
    uint256 dividendPerToken = profits / circulatingTokens(); // Tokens held by contract do not participate in dividends


    uint256 holderIndex = persistance().holderIndex();
    for (uint i = 0; i<holderIndex; i++) {
      address holder = persistance().tokenHolders(i);
      if (holder != manager) {
        persistance().operateDividend(holder, int256(persistance().balances(holder)) * int256(dividendPerToken));
      }
    }

    Dividends(dividendPerToken);

    mintingAllowed = true;

    return true;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
      //Default assumes totalSupply can't be over max (2>=256 - 1).
      //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
      //Replace the if with this one instead.
      //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      if (persistance().balances(msg.sender) >= _value && _value > 0) {
          persistance().operateBalance(msg.sender, int256(-1) * int256(_value));
          persistance().operateBalance(_to, int256(_value));

          Transfer(msg.sender, _to, _value);
          return true;
      } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      //same as above. Replace this line with the following if you want to protect against wrapping uints.
      //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      if (persistance().balances(_from) >= _value && persistance().allowed(_from, msg.sender) >= _value && _value > 0) {
          persistance().operateBalance(_to, int256(_value));
          persistance().operateBalance(_from, int256(-1) * int256(_value));
          persistance().operateAllowance(_from, msg.sender, int256(-1) * int256(_value));

          Transfer(_from, _to, _value);
          return true;
      } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
      return persistance().balances(_owner);
  }

  function dividendOf(address _owner) constant returns (uint256) {
      return persistance().dividends(_owner);
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
      persistance().operateAllowance(msg.sender, _spender, int256(_value));
      Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return persistance().allowed(_owner, _spender);
  }

  function persistance() returns (InvestmentPersistance) {
    return InvestmentPersistance(addressFor('InvestmentDB'));
  }

  function() {
    throw;
  }
}
