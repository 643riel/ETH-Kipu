// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Intercambio Descentralizado Simple (DEX)
/// @notice Este contrato facilita los intercambios de tokens y la gestión de liquidez
/// @dev Utiliza la fórmula de producto constante para los intercambios
/// @author [Gabriel iakantas]
contract SimpleDEX is Ownable {
    /// @notice Token A en el pool de liquidez
    IERC20 public tokenA;

    /// @notice Token B en el pool de liquidez
    IERC20 public tokenB;

    /// @notice Emitido cuando se agrega liquidez
    /// @param amountA La cantidad de token A añadida
    /// @param amountB La cantidad de token B añadida
    event LiquidityAdded(uint256 amountA, uint256 amountB);

    /// @notice Emitido cuando se retira liquidez
    /// @param amountA La cantidad de token A retirada
    /// @param amountB La cantidad de token B retirada
    event LiquidityRemoved(uint256 amountA, uint256 amountB);

    /// @notice Emitido cuando ocurre un intercambio de tokens
    /// @param user La dirección del usuario que realiza el intercambio
    /// @param amountIn La cantidad de tokens de entrada
    /// @param amountOut La cantidad de tokens de salida
    event TokenSwapped(address indexed user, uint256 amountIn, uint256 amountOut);

    /// @notice Inicializa el DEX con dos tokens
    /// @param _tokenA Dirección del token A
    /// @param _tokenB Dirección del token B
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Agrega liquidez al pool
    /// @dev Solo puede ser llamado por el propietario
    /// @param amountA La cantidad de token A para agregar
    /// @param amountB La cantidad de token B para agregar
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        emit LiquidityAdded(amountA, amountB);
    }

    /// @notice Retira liquidez del pool
    /// @dev Solo puede ser llamado por el propietario
    /// @param amountA La cantidad de token A para retirar
    /// @param amountB La cantidad de token B para retirar
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        
        require(amountA <= balanceA && amountB <= balanceB, "Low liquidity");

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB);
    }

    /// @notice Intercambia token A por token B
    /// @param amountAIn La cantidad de token A para intercambiar
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be > 0");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        uint256 amountBOut = getAmountOut(amountAIn, balanceA, balanceB);

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        emit TokenSwapped(msg.sender, amountAIn, amountBOut);
    }

    /// @notice Intercambia token B por token A
    /// @param amountBIn La cantidad de token B para intercambiar
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be > 0");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));
        uint256 amountAOut = getAmountOut(amountBIn, balanceB, balanceA);

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        emit TokenSwapped(msg.sender, amountBIn, amountAOut);
    }

    /// @notice Obtiene el precio de un token en relación con el otro
    /// @param _token Dirección del token para obtener su precio
    /// @return El precio en términos del otro token
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");

        uint256 balanceA = tokenA.balanceOf(address(this));
        uint256 balanceB = tokenB.balanceOf(address(this));

        return (_token == address(tokenA))
            ? (balanceB * 1e18) / balanceA
            : (balanceA * 1e18) / balanceB;
    }

    /// @notice Calcula la cantidad de tokens que se obtendrán en un intercambio
    /// @dev Implementa la fórmula de producto constante
    /// @param amountIn La cantidad de tokens de entrada
    /// @param reserveIn La reserva del token de entrada
    /// @param reserveOut La reserva del token de salida
    /// @return La cantidad de tokens de salida
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
