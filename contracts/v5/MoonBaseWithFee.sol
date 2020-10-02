pragma solidity ^0.5.16;

import "@openzeppelin/2.3.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/2.3.0/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/2.3.0/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/2.3.0/contracts/math/SafeMath.sol";

contract MoonBaseWithFee is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    IERC20 public based;

    uint public exitFeeLow; // % exit fee back to the moon base as reward e18
    uint public exitFeeHigh; // % exit fee back to the moon base as reward e18
    uint public vestingTime; // vesting time in sec
    mapping(address => uint) public depositTimes;

    constructor (address _based, uint _exitFeeLow, uint _exitFeeHigh, uint _vestingTime)
        public
        ERC20Detailed("MoonBase BASED", "mbBASED", 18)
    {
        based = IERC20(_based);
        exitFeeLow = _exitFeeLow;
        exitFeeHigh = _exitFeeHigh;
        vestingTime = _vestingTime;
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

    function getExitFee(address account) public view returns (uint) {
        uint timeDelta = block.timestamp.sub(depositTimes[account]);
        if (timeDelta < vestingTime) {
            uint vestDelta = vestingTime.sub(timeDelta);
            uint feeDelta = exitFeeHigh.sub(exitFeeLow);
            return exitFeeLow.add(feeDelta.mul(vestDelta).div(vestingTime));
        }
        return exitFeeLow;
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
        depositTimes[msg.sender] = block.timestamp;
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        // % of withdraw is distributed back to the pool as reward
        uint giftToTheMoonBase = _shares.mul(getExitFee(msg.sender)).div(1e20);
        uint _sharesToWithdraw = _shares.sub(giftToTheMoonBase);

        uint _pool = balance();
        uint _basedAmount = _pool.mul(_sharesToWithdraw).div(totalSupply());
        based.transfer(msg.sender, _basedAmount);
        _burn(msg.sender, _shares);
    }
}
