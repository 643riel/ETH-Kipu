
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

// File: SimpleDEX.sol


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
