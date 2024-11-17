// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    address public tokenA;
    address public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event TokensSwapped(address indexed trader, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Cannot add zero liquidity");

        // Transferir tokens al contrato
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Actualizar reservas
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(reserveA >= amountA && reserveB >= amountB, "Insufficient liquidity");

        // Transferir tokens al owner
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        // Actualizar reservas
        reserveA -= amountA;
        reserveB -= amountB;

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Invalid input amount");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        uint256 amountBOut = (reserveB * amountAIn) / (reserveA + amountAIn);

        require(amountBOut > 0, "Insufficient output amount");

        // Transferir TokenA al contrato
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);

        // Transferir TokenB al usuario
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        // Actualizar reservas
        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, tokenA, tokenB, amountAIn, amountBOut);
    }

    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Invalid input amount");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Calcular la cantidad de TokenA que se puede retirar según la fórmula del producto constante
        uint256 amountAOut = (reserveA * amountBIn) / (reserveB + amountBIn);

        require(amountAOut > 0, "Insufficient output amount");

        // Transferir TokenB del usuario al contrato
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);

        // Transferir TokenA del contrato al usuario
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        // Actualizar las reservas
        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, tokenB, tokenA, amountBIn, amountAOut);
    }

    function getPrice(address _token) external view returns (uint256) {
        require(_token == tokenA || _token == tokenB, "Invalid token address");

        if (_token == tokenA) {
            return (reserveB * 1e18) / reserveA; // Precio de TokenA en términos de TokenB
        } else {
            return (reserveA * 1e18) / reserveB; // Precio de TokenB en términos de TokenA
        }
    }

}
