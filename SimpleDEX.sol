// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    address public tokenA;  // Address of the first token (Token A)
    address public tokenB;  // Address of the second token (Token B)

    uint256 public reserveA; // Reserve of Token A in the pool
    uint256 public reserveB; // Reserve of Token B in the pool

    mapping(address => uint256) public liquidityA;
    mapping(address => uint256) public liquidityB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event TokensSwapped(
        address indexed trader,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool direction // true: A -> B, false: B -> A
    );

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Zero liquidity");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        liquidityA[msg.sender] += amountA;
        liquidityB[msg.sender] += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(reserveA >= amountA && reserveB >= amountB, "Low liquidity");

        uint256 userLiquidityA = liquidityA[msg.sender];
        uint256 userLiquidityB = liquidityB[msg.sender];

        require(userLiquidityA >= amountA, "Exceeds Token A");
        require(userLiquidityB >= amountB, "Exceeds Token B");

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        reserveA -= amountA;
        reserveB -= amountB;

        liquidityA[msg.sender] -= amountA;
        liquidityB[msg.sender] -= amountB;

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Zero input");

        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;

        require(_reserveA > 0 && _reserveB > 0, "Low liquidity");

        uint256 amountBOut = _reserveB - (_reserveA * _reserveB) / (_reserveA + amountAIn);
        require(amountBOut > 0, "Low output");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, tokenA, tokenB, amountAIn, amountBOut, true);
    }

    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Zero input");

        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;

        require(_reserveA > 0 && _reserveB > 0, "Low liquidity");

        uint256 amountAOut = _reserveA - (_reserveA * _reserveB) / (_reserveB + amountBIn);
        require(amountAOut > 0, "Low output");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, tokenB, tokenA, amountBIn, amountAOut, false);
    }

    function getPrice(address _token) external view returns (uint256) {
        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;

        if (_token == tokenA) {
            return (_reserveB * 1e18) / _reserveA;
        } else if (_token == tokenB) {
            return (_reserveA * 1e18) / _reserveB;
        } else {
            revert("Invalid token");
        }
    }
}
