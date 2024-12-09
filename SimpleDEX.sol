// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleDEX is Ownable {
    address public tokenA; // Dirección del primer token (Token A)
    address public tokenB; // Dirección del segundo token (Token B)

    uint256 public reserveA; // Reserva del Token A en el pool
    uint256 public reserveB; // Reserva del Token B en el pool

    event LiquidityAdded(uint256 amountA, uint256 amountB);
    event LiquidityRemoved(uint256 amountA, uint256 amountB);
    event TokensSwapped(
        address indexed trader,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bool direction // true: A -> B, false: B -> A
    );

    /// @notice Constructor para inicializar los tokens
    /// @param _tokenA Dirección del Token A
    /// @param _tokenB Dirección del Token B
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        require(_tokenA != _tokenB, "Tokens must be different");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    /// @notice Agrega liquidez al pool (solo el propietario puede llamar)
    /// @param amountA Cantidad de Token A para agregar
    /// @param amountB Cantidad de Token B para agregar
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Zero liquidity");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(amountA, amountB);
    }

    /// @notice Remueve liquidez del pool (solo el propietario puede llamar)
    /// @param amountA Cantidad de Token A para retirar
    /// @param amountB Cantidad de Token B para retirar
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(reserveA >= amountA && reserveB >= amountB, "Low liquidity");

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        reserveA -= amountA;
        reserveB -= amountB;

        emit LiquidityRemoved(amountA, amountB);
    }

    /// @notice Intercambia Token A por Token B
    /// @param amountAIn Cantidad de Token A a intercambiar
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Zero input");
        require(reserveA > 0 && reserveB > 0, "Low liquidity");

        uint256 amountBOut = (amountAIn * reserveB) / (reserveA + amountAIn);
        require(amountBOut > 0, "Low output");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, tokenA, tokenB, amountAIn, amountBOut, true);
    }

    /// @notice Intercambia Token B por Token A
    /// @param amountBIn Cantidad de Token B a intercambiar
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Zero input");
        require(reserveA > 0 && reserveB > 0, "Low liquidity");

        uint256 amountAOut = (amountBIn * reserveA) / (reserveB + amountBIn);
        require(amountAOut > 0, "Low output");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, tokenB, tokenA, amountBIn, amountAOut, false);
    }

    /// @notice Obtiene el precio de un token relativo al otro
    /// @param _token Dirección del token a evaluar
    /// @return El precio en términos del otro token
    function getPrice(address _token) external view returns (uint256) {
        require(_token == tokenA || _token == tokenB, "Invalid token");

        if (_token == tokenA) {
            return (reserveB * 1e18) / reserveA;
        } else {
            return (reserveA * 1e18) / reserveB;
        }
    }
}
