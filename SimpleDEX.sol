// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Decentralized Exchange (DEX)
/// @notice Contrato para intercambiar tokens y gestionar liquidez
/// @dev Implementa la fórmula de producto constante para intercambios
/// @author [Gabriel Iakantas]
contract SimpleDEX is Ownable {
    /// @notice Token A en el pool de liquidez
    IERC20 public tokenA;

    /// @notice Token B en el pool de liquidez
    IERC20 public tokenB;

    /// @notice Evento emitido al agregar liquidez
    /// @param amountA Cantidad de token A agregada
    /// @param amountB Cantidad de token B agregada
    event LiquidityAdded(uint256 amountA, uint256 amountB);

    /// @notice Evento emitido al remover liquidez
    /// @param amountA Cantidad de token A removida
    /// @param amountB Cantidad de token B removida
    event LiquidityRemoved(uint256 amountA, uint256 amountB);

    /// @notice Evento emitido al realizar un intercambio
    /// @param user Dirección del usuario que realizó el intercambio
    /// @param amountIn Cantidad del token de entrada
    /// @param amountOut Cantidad del token de salida
    event TokenSwapped(address indexed user, uint256 amountIn, uint256 amountOut);

    /// @notice Constructor para inicializar el contrato con los tokens
    /// @param _tokenA Dirección del token A
    /// @param _tokenB Dirección del token B
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Token address cannot be 0");
        require(_tokenA != _tokenB, "Tokens must be different");
        
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Agrega liquidez al pool
    /// @dev Solo puede ser llamado por el propietario
    /// @param amountA Cantidad de token A a agregar
    /// @param amountB Cantidad de token B a agregar
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(amountA, amountB);
    }

    /// @notice Remueve liquidez del pool
    /// @dev Solo puede ser llamado por el propietario
    /// @param amountA Cantidad de token A a remover
    /// @param amountB Cantidad de token B a remover
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        require(amountA <= balanceA && amountB <= balanceB, "Not enough liquidity available");

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB);
    }

    /// @notice Intercambia token A por token B
    /// @param amountAIn Cantidad de token A para intercambiar
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Input amount must be > 0");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        require(balanceA > 0 && balanceB > 0, "Insufficient liquidity");

        uint256 amountBOut = getAmountOut(amountAIn, balanceA, balanceB);

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        emit TokenSwapped(msg.sender, amountAIn, amountBOut);
    }

    /// @notice Intercambia token B por token A
    /// @param amountBIn Cantidad de token B para intercambiar
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Input amount must be > 0");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        require(balanceA > 0 && balanceB > 0, "Insufficient liquidity");

        uint256 amountAOut = getAmountOut(amountBIn, balanceB, balanceA);

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        emit TokenSwapped(msg.sender, amountBIn, amountAOut);
    }

    /// @notice Calcula el precio relativo de un token
    /// @param _token Dirección del token a evaluar
    /// @return Precio relativo en términos del otro token
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token address");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        return _token == address(tokenA)
            ? (balanceB * 1e18) / balanceA
            : (balanceA * 1e18) / balanceB;
    }

    /// @notice Calcula la cantidad de tokens de salida basándose en la fórmula de producto constante
    /// @param amountIn Cantidad de tokens de entrada
    /// @param reserveIn Reserva del token de entrada
    /// @param reserveOut Reserva del token de salida
    /// @return Cantidad de tokens de salida
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "Insufficient reserves");
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
