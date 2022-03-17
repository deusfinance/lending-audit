// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

contract Oracle is AccessControl {
    uint256 public validTime;
    uint256 public twapPrice;
    uint256 public minReqSigs;
    uint256 public lastTimestamp;
    address public lp;
    address public muonContract;
    uint32 public APP_ID;

    modifier isAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ORACLE: caller is not admin"
        );
        _;
    }

    constructor(
        address lp_,
        address muon_,
        address admin,
        uint256 minReqSigs_,
        uint256 validTime_,
        uint256 twapPrice_,
        uint32 appId
    ) {
        lp = lp_;
        muonContract = muon_;
        minReqSigs = minReqSigs_;
        validTime = validTime_;
        twapPrice = twapPrice_;
        lastTimestamp = block.timestamp;
        APP_ID = appId;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function updatePrice(
        uint256 twapPrice_,
        uint256 timestamp,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external {
        require(
            sigs.length >= minReqSigs,
            "ORACLE: insufficient number of signatures"
        );
        require(timestamp > lastTimestamp, "ORACLE: price is expired");
        bytes32 hash = keccak256(
            abi.encodePacked(APP_ID, lp, twapPrice_, timestamp)
        );
        require(
            IMuonV02(muonContract).verify(_reqId, uint256(hash), sigs),
            "ORACLE: not verified"
        );
        lastTimestamp = block.timestamp;
        twapPrice = twapPrice_;
    }

    function getPrice() external view returns (uint256) {
        require(
            (block.timestamp - lastTimestamp) <= validTime,
            "ORACLE: price is not valid"
        );
        return twapPrice;
    }

    function setMuonContract(address muon) external isAdmin {
        muonContract = muon;
    }

    function setMinReqSig(uint256 minReqSigs_) external isAdmin {
        minReqSigs = minReqSigs_;
    }

    function setValidTime(uint256 validTime_) external isAdmin {
        validTime = validTime_;
    }

    function setAppId(uint8 APP_ID_) external isAdmin {
        APP_ID = APP_ID_;
    }
}
