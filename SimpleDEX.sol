// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    address public tokenA;  // Address of the first token (Token A)
    address public tokenB;  // Address of the second token (Token B)

    uint256 public reserveA; // Reserve of Token A in the pool
    uint256 public reserveB; // Reserve of Token B in the pool

    // Events to log important actions
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event TokensSwapped(address indexed trader, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    // Constructor to initialize the token addresses
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /// @notice Adds liquidity to the pool by transferring tokens from the provider to the contract
    /// @param amountA The amount of Token A to be added to the liquidity pool
    /// @param amountB The amount of Token B to be added to the liquidity pool
    /// @dev No need to validate that amountA and amountB are less than or equal to the approved amount, 
    /// as the ERC-20 transferFrom function automatically reverts the transaction if the approval is insufficient.
    //  (En un momento pensé en agregar más validaciones, pero dsp me di cuenta que no es necesario). 
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        // Require non-zero amounts to be added to the liquidity pool
        require(amountA > 0 && amountB > 0, "Cannot add zero liquidity");

        // Transfer the specified amounts of Token A and Token B from the provider to the contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Update the reserves in the contract after adding liquidity
        reserveA += amountA;
        reserveB += amountB;

        // Emit an event to log the liquidity addition
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /// @notice Removes liquidity from the pool by transferring tokens from the contract to the provider
    /// @param amountA The amount of Token A to be removed from the liquidity pool
    /// @param amountB The amount of Token B to be removed from the liquidity pool
    function removeLiquidity(uint256 amountA, uint256 amountB) external {
        // Require that the amounts to be removed are valid and within the pool's liquidity
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(reserveA >= amountA && reserveB >= amountB, "Insufficient liquidity");

        // Transfer the specified amounts of Token A and Token B back to the provider
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        // Update the reserves in the contract after removing liquidity
        reserveA -= amountA;
        reserveB -= amountB;

        // Emit an event to log the liquidity removal
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /// @notice Swaps Token A for Token B using the constant product formula (X * Y = k)
    /// @param amountAIn The amount of Token A to be exchanged for Token B
    function swapAforB(uint256 amountAIn) external {
		// amountAIn represents the amount of Token A the user is paying to buy Token B.
        // Require that the input amount is valid (greater than zero)
        require(amountAIn > 0, "Invalid input amount");

        // Ensure there is enough liquidity in both reserves
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Calculate the amount of Token B to output, based on the constant product formula
        // Formula: dy = y0 - (x0 * y0) / (x0 + dx), where dx is the input amount (amountAIn)
        // (entiendo que esto es lo que había que hacer). 
        uint256 amountBOut = reserveB - (reserveA * reserveB) / (reserveA + amountAIn);
        require(amountBOut > 0, "Insufficient output amount");

        // Transfer the input Token A from the user to the contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);

        // Transfer the calculated amount of Token B to the user
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        // Update the reserves in the contract after the swap
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // Emit an event to log the swap
        emit TokensSwapped(msg.sender, tokenA, tokenB, amountAIn, amountBOut);
    }

    /// @notice Swaps Token B for Token A using the constant product formula (X * Y = k)
    /// @param amountBIn The amount of Token B to be exchanged for Token A
    function swapBforA(uint256 amountBIn) external {
		// amountBIn represents the amount of Token B the user is paying to buy Token A.
        // Require that the input amount is valid (greater than zero)
        require(amountBIn > 0, "Invalid input amount");

        // Ensure there is enough liquidity in both reserves
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Calculate the amount of Token A to output, based on the constant product formula
        // Formula: dx = (x0 * y0) / (y0 - dy) - x0, where dy is the input amount (amountBIn)
        uint256 amountAOut = reserveA - (reserveA * reserveB) / (reserveB + amountBIn);
        require(amountAOut > 0, "Insufficient output amount");

        // Transfer the input Token B from the user to the contract
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);

        // Transfer the calculated amount of Token A to the user
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        // Update the reserves in the contract after the swap
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // Emit an event to log the swap
        emit TokensSwapped(msg.sender, tokenB, tokenA, amountBIn, amountAOut);
    }

    /// @notice Gets the current price of a token in terms of the other token in the pool
    /// @param _token The address of the token whose price is being queried
    /// @return The price of the given token in terms of the other token
    function getPrice(address _token) external view returns (uint256) {
        // Ensure the token address is either Token A or Token B
        require(_token == tokenA || _token == tokenB, "Invalid token address");

        // If the queried token is Token A, return its price in terms of Token B
        // 1e18 is used to scale the result and maintain precision, avoiding floating-point errors

        uint256 price;
        if (_token == tokenA) {
            price = (reserveB * 1e18) / reserveA; // Price of Token A in terms of Token B
        } else {
            price = (reserveA * 1e18) / reserveB; // Price of Token B in terms of Token A
        }

        // Convert the result to the "real" price by dividing by 1e18
        return price / 1e18;
    }

}