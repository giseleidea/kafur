pragma solidity >=0.4.4;

import "./Owned.sol";

contract Server is Owned {
  mapping (bytes32 => address) private services;
  mapping (bytes32 => address) private persistance;

  mapping (uint8 => bytes32) private allServices;
  uint8 private allServicesIndex;

  modifier onlyServices {
    for (uint8 i = 0; i<allServicesIndex; i++) {
      if (msg.sender == services[allServices[allServicesIndex]]) {
        _;
        return;
      }
    }
    throw;
  }

  function addService(address newService) onlyOwner {
    Binded service = Binded(newService);
    bytes32 h = service.identifier();
    if (services[h] != 0x0) {
      Binded(services[h]).destroy();
    }

    services[h] = newService;
  }

  function addPersistance(address newPersistance) onlyOwner {
    Binded db = Binded(newPersistance);
    bytes32 h = db.identifier();

    var oldPersistance = persistance[h];
    persistance[h] = newPersistance;

    if (oldPersistance != 0x0) {
      // TODO: Implement persistance migrations
      Binded(oldPersistance).destroy();
      // assignAllPermissions();
    }
  }

  function addressFor(string identifier) constant returns (address) {
    return addressForHash(sha3(identifier));
  }

  function addressForHash(bytes32 h) constant returns (address) {
    if (services[h] != 0x0) {
      return services[h];
    }

    if (persistance[h] != 0x0) {
      return persistance[h];
    }

    throw;
  }

  function assignAllPermissions();
  function sendFunds(address recipient, uint256 amount, string concept, bool isDividend) returns (bool);
}

contract Binded {
  enum PermissionLevel {
    None,
    Read,
    Write,
    Manager
  }

  mapping (address => PermissionLevel) private permissions;
  address public manager;

  bytes32 public identifier;

  function Binded(string _identifier) {
    permissions[msg.sender] = PermissionLevel.Manager;
    manager = msg.sender;

    identifier = sha3(_identifier);
  }

  function addressFor(string _id) returns (address) {
    return Server(manager).addressForHash(sha3(_id));
  }


  function destroy() requiresPermission(PermissionLevel.Manager) {
    selfdestruct(manager);
  }


  function transferManagement(address newManager) requiresPermission(PermissionLevel.Manager) {
    manager = newManager;
    permissions[newManager] = PermissionLevel.Manager;
  }

  function assignPermission(address allowed, PermissionLevel level) requiresPermission(PermissionLevel.Manager) {
    permissions[allowed] = level;
  }

  modifier requiresPermission(PermissionLevel requiredPermission) {
    if (uint(permissions[msg.sender]) < uint(requiredPermission)) { throw; }
    else
      _;
  }
}
