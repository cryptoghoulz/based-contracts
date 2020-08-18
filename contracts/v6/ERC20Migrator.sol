// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Migrator {
    using SafeMath for uint256;

    IERC20 public legacyToken;
    IERC20 public newToken;

    uint256 public totalMigrated;

    constructor (address _legacyToken, address _newToken) public {
        require(_legacyToken != address(0), "legacyToken address is required");
        require(_newToken != address(0), "_newToken address is required");

        legacyToken = IERC20(_legacyToken);
        newToken = IERC20(_newToken);
    }

    function migrate(address account, uint256 amount) internal {
        legacyToken.transferFrom(account, address(this), amount);
        newToken.transfer(account, amount);
        totalMigrated = totalMigrated.add(amount);
    }

    function migrateAll() public {
        address account = msg.sender;
        uint256 balance = legacyToken.balanceOf(account);
        uint256 allowance = legacyToken.allowance(account, address(this));
        uint256 amount = Math.min(balance, allowance);
        require(amount > 0, "ERC20Migrator::migrateAll: Approval and balance must be > 0");
        migrate(account, amount);
    }
}
