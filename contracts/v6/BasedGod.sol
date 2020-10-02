//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IPoolFactory.sol";
import "./RoverVault.sol";
import "./FarmingRover.sol";

contract BasedGod {
    address[] public rovers;
    // rewardToken => rover address array
    mapping(address => address[]) public tokenRover;
    address public immutable moonBase;
    address public immutable based;
    address public immutable susd;
    address public immutable weth;
    // mainnet 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    address public immutable uniswapRouter;
    address public immutable poolFactory;

    constructor (
        address _based,
        address _moonBase,
        address _susd,
        address _weth,
        address _uniswapRouter,
        address _poolFactory
    ) public {
        susd = _susd;
        based = _based;
        moonBase = _moonBase;
        weth = _weth;
        uniswapRouter = _uniswapRouter;
        poolFactory = _poolFactory;
    }

    function getRovers() public view returns (address[] memory) {
        return rovers;
    }

    function getTokenRovers(address token) public view returns (address[] memory) {
        return tokenRover[token];
    }

    /// @dev Use this Rover if you want to depoit tokens directly to Rover contract and you don't need to farm
    /// @param _rewardToken address of the reward token
    /// @param _pair through which pair do you want to sell reward tokens, either "sUSD" or "WETH"
    function createNewRoverVault(address _rewardToken, string calldata _pair) external returns (RoverVault rover) {
        rover = new RoverVault(based, _rewardToken, _pair);
        rover.transferOwnership(msg.sender);
        _saveRover(_rewardToken, address(rover));
    }

    /// @dev Use this Rover if you have a reward pool and you want the Rover to farm it
    /// @param _rewardToken address of the reward token
    /// @param _pair either "sUSD" or "WETH"
    function createNewFarmingRover(address _rewardToken, string calldata _pair) external returns (FarmingRover rover) {
        rover = new FarmingRover(based, _rewardToken, _pair);
        rover.transferOwnership(msg.sender);
        _saveRover(_rewardToken, address(rover));
    }

    /// @dev Use this if you want to deploy Farming Rover and Pool at once
    /// @param _distributor who can notify of rewards
    function createNewFarmingRoverAndPool(
        address _rewardToken,
        address _distributor,
        string calldata _pair,
        uint256 _duration
    ) external returns (FarmingRover rover, address rewardsPool) {
        require(_distributor != address(0), "someone has to notify of rewards and it ain't us");

        rover = new FarmingRover(based, _rewardToken, _pair);
        _saveRover(_rewardToken, address(rover));

        rewardsPool = IPoolFactory(poolFactory).createNewPool(
            _rewardToken,
            address(rover),
            _duration,
            _distributor
        );

        rover.startRover(rewardsPool);
    }

    function _saveRover(address _rewardToken, address _rover) internal {
        rovers.push(address(_rover));
        tokenRover[_rewardToken].push(address(_rover));
    }
}
