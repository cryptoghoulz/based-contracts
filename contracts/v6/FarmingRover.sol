//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interface/IPool.sol";
import "./Rover.sol";

contract FarmingRover is Rover, ERC20, ReentrancyGuard {
    IPool public rewardPool;

    /// @param _pair either "sUSD" or "WETH"
    constructor (
        address _based,
        address _rewardToken,
        string memory _pair
    )
        public
        Rover(_based, _rewardToken, _pair)
        ERC20(
            string(abi.encodePacked("Rover ", ERC20(_rewardToken).name())),
            string(abi.encodePacked("r", ERC20(_rewardToken).symbol()))
        )
    {
        // Mint the single token
        _mint(address(this), 1);
    }

    function earned() public view returns (uint256){
        return rewardPool.earned(address(this));
    }

    function startRover(address _rewardPool)
        public
        onlyOwner
    {
        init();

        this.approve(_rewardPool, 1);
        rewardPool = IPool(_rewardPool);
        rewardPool.stake(1);
    }

    function rugPull() public override nonReentrant {
        claimReward();

        // this couses reentracy
        super.rugPull();
    }

    function claimReward() internal {
        // ignore errors
        (bool success,) = address(rewardPool).call(abi.encodeWithSignature("getReward()"));
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(balanceOf(address(this)) == 1, "NOT BASED: only one transfer allowed.");
        require(recipient == address(rewardPool),
            "NOT BASED: Recipient address must be equal to rewardPool address.");
        super._transfer(sender, recipient, amount);
    }
}
