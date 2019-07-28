pragma solidity >=0.4.4;

contract Updates {
  address public owner;
  uint public last_completed_update;

  modifier restricted() {
    if (msg.sender == owner)
      _;
  }

  function Updates() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_update = completed;
  }

  function upgrade(address new_address) restricted {
    Updates upgraded = Updates(new_address);
    upgraded.setCompleted(last_completed_update);
  }
}
