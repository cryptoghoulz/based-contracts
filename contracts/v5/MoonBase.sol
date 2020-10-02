pragma solidity ^0.5.16;

import "@openzeppelin/2.3.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/2.3.0/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/2.3.0/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/2.3.0/contracts/math/SafeMath.sol";

contract MoonBase is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    IERC20 public based;

    constructor (address _based, string memory name, string memory symbol)
        public
        ERC20Detailed(name, symbol, 18)
    {
        based = IERC20(_based);
    }

    function balance() public view returns (uint) {
        return based.balanceOf(address(this));
    }

    /// Returns price in BASED per share e18
    function getPricePerFullShare() public view returns (uint) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return balance().mul(1e18).div(supply);
    }

    function depositAll() external {
        deposit(based.balanceOf(msg.sender));
    }

    /// @param _amount amount in BASED to deposit
    function deposit(uint _amount) public {
        require(_amount > 0, "Nothing to deposit");

        uint _pool = balance();
        based.transferFrom(msg.sender, address(this), _amount);
        uint _after = balance();
        _amount = _after.sub(_pool); // Additional check for deflationary baseds
        uint shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        uint _pool = balance();
        uint _basedAmount = _pool.mul(_shares).div(totalSupply());
        based.transfer(msg.sender, _basedAmount);
        _burn(msg.sender, _shares);
    }
}
