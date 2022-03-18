// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: GPL3.0-or-later

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Mint Helper ===================
// ======================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMintHelper.sol";
import "./interfaces/IDEIStablecoin.sol";

/// @title Mint Helper
/// @author DEUS Finance
/// @notice DEI minter contract for lending contracts
contract MintHelper is IMintHelper, AccessControl {
    address public dei;
    mapping(address => bool) public useVirtualReserve;
    uint256 public virtualReserve;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier isMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not minter");
        _;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    constructor(
        address dei_,
        uint256 virtualReserve_,
        address admin
    ) {
        dei = dei_;
        virtualReserve = virtualReserve_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice mint DEI for user
    /// @param recv DEI reciever
    /// @param amount DEI amount
    function mint(address recv, uint256 amount) external isMinter {
        if (useVirtualReserve[msg.sender]) {
            virtualReserve += amount;
        }
        IDEIStablecoin(dei).pool_mint(recv, amount);
    }

    /// @notice burn DEI from user
    /// @param from burnt user
    /// @param amount DEI amount
    function burnFrom(address from, uint256 amount) external isMinter {
        if (useVirtualReserve[msg.sender]) {
            virtualReserve -= amount;
        }
        IDEIStablecoin(dei).burnFrom(from, amount);
    }

    /// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
    /// @dev simulates the collateral in the contract
    /// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
    /// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price)
        public
        view
        returns (uint256)
    {
        uint256 deiCollateralRatio = IDEIStablecoin(dei)
            .global_collateral_ratio();
        return (virtualReserve * collat_usd_price * deiCollateralRatio) / 1e12;
    }

    /// @notice sets virtualReserve
    /// @dev only admin can call function
    /// @param virtualReserve_ new virtualReserve amount
    function setVirtualReserve(uint256 virtualReserve_) external isAdmin {
        virtualReserve = virtualReserve_;
    }

    /// @notice set useVirtualReserve for specific minter
    /// @dev only admin can call function
    function setUseVirtualReserve(address pool, bool state) external isAdmin {
        useVirtualReserve[pool] = state;
    }
}