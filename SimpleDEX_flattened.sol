
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: SimpleDEX.sol

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
