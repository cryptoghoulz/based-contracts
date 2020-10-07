//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interface/IBasedGod.sol";
import "./interface/ISakeSwapRouter.sol";

contract SakeRover is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant vestingTime = 365*24*60*60; // 1 year
    address public constant sakeSwapRouter = 0x9C578b573EdE001b95d51a55A3FAfb45f5608b1f;

    uint256 public roverStart;
    uint256 public latestBalance;
    uint256 public totalTokensReceived;
    uint256 public totalTokensWithdrawn;
    address[] public path;
    address[] public sakePath;

    IBasedGod public basedGod;
    IERC20 public immutable based;
    IERC20 public immutable rewardToken;

    modifier updateBalance() {
        sync();
        _;
        latestBalance = rewardToken.balanceOf(address(this));
    }

    constructor (
        address _rewardToken
    )
        public
    {
        basedGod = IBasedGod(0x8c879436D018c044f009F9E96f0Db3DEb895CED4);

        // set immutables
        based = IERC20(basedGod.based());
        rewardToken = IERC20(_rewardToken);

        address[] memory _sakePath = new address[](2);
        _sakePath[0] = _rewardToken;
        _sakePath[1] = basedGod.weth();
        sakePath = _sakePath;

        address[] memory _path = new address[](2);
        _path[0] = basedGod.weth();
        _path[1] = basedGod.based();
        path = _path;

        // ensure that the path exists
        uint[] memory amountsOut = IUniswapV2Router02(basedGod.uniswapRouter()).getAmountsOut(10**10, _path);
        require(amountsOut[amountsOut.length - 1] >= 1, "Path does not exist");
        // ensure that the sake path exists
        uint[] memory sakeAmountsOut = ISakeSwapRouter(sakeSwapRouter).getAmountsOut(10**10, _sakePath);
        require(sakeAmountsOut[sakeAmountsOut.length - 1] >= 1, "Sake path does not exist");
    }

    function balance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function calculateReward() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(roverStart);
        if (timeElapsed > vestingTime) timeElapsed = vestingTime;
        uint256 maxClaimable = totalTokensReceived.mul(timeElapsed).div(vestingTime);
        return maxClaimable.sub(totalTokensWithdrawn);
    }

    function startRover() public onlyOwner {
        init();
    }

    function rugPull() public virtual updateBalance {
        require(roverStart != 0, "Rover is not initialized");

        // Calculate how much reward can be swapped
        uint256 availableReward = calculateReward();

        // Record that the tokens are being withdrawn
        totalTokensWithdrawn = totalTokensWithdrawn.add(availableReward);
        // Swap for BASED
        uint256 basedReward = swapReward(swapSake(availableReward));

        // Split the reward between the caller and the moonbase contract
        uint256 callerReward = basedReward.div(100);
        uint256 moonbaseReward = basedReward.sub(callerReward);

        // Reward the caller
        based.transfer(msg.sender, callerReward);
        // Send to MoonBase
        based.transfer(basedGod.moonBase(), moonbaseReward);
    }

    function init() internal updateBalance {
        require(roverStart == 0, "Already initialized");
        roverStart = block.timestamp;
        renounceOwnership();
    }

    function sync() internal {
        uint256 currentBalance = rewardToken.balanceOf(address(this));
        if (currentBalance > latestBalance) {
            uint diff = currentBalance.sub(latestBalance);
            totalTokensReceived = totalTokensReceived.add(diff);
        }
    }

    function swapSake(uint256 amountIn) internal returns (uint256) {
        rewardToken.safeApprove(sakeSwapRouter, 0);
        rewardToken.safeApprove(sakeSwapRouter, amountIn);
        uint256 amountOutMin = 1;
        uint256[] memory amounts =
            ISakeSwapRouter(sakeSwapRouter).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                sakePath,
                address(this),
                block.timestamp,
                false
            );
        return amounts[amounts.length - 1];
    }

    function swapReward(uint256 amountIn) internal returns (uint256){
        // ensure we have no over-approval
        IERC20(path[0]).safeApprove(basedGod.uniswapRouter(), 0);
        IERC20(path[0]).safeApprove(basedGod.uniswapRouter(), amountIn);
        // This amount is only used in a sanity check before the swap.
        // We cannot change routes, and if we calculate this value via smart contract calls
        // we would end up with the same result
        // tl;dr YOLO
        uint256 amountOutMin = 1;
        uint256[] memory amounts =
            IUniswapV2Router02(basedGod.uniswapRouter()).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
        return amounts[amounts.length - 1];
    }
}
