// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.10;

interface IDEIStablecoin {
    function global_collateral_ratio() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burnFrom(address b_address, uint256 b_amount) external;

    function pool_mint(address m_address, uint256 m_amount) external;
}
