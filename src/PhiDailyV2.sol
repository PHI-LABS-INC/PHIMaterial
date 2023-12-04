// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/security/Pausable.sol";
import { Context } from "@openzeppelin/utils/Context.sol";
import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";

import { IMaterialObject } from "./interfaces/IMaterialObject.sol";
import { IEmissionLogic } from "./interfaces/IEmissionLogic.sol";
import { MultiOwner } from "./utils/MultiOwner.sol";
import { CouponArray } from "./utils/Array.sol";
import { Coupon } from "./types/Coupon.sol";

/// @title Users claim MaterialObjects
/// @dev This contract handles the claims of MaterialObjects by users.
/// The contract utilizes ECDSA for secure, non-repudiable claims.
/// It also includes an emission logic contract to determine the ID of the token to be emitted.
/// The emission logic can be set by the contract owner.
/// This contract has been upgraded to include OpenZeppelin's access control for role-based permissions.
contract PhiDailyV2 is ERC2771Context, MultiOwner, ReentrancyGuard, Pausable {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    using CouponArray for Coupon[];

    // The address that signs the claims (admin).
    address public adminSigner;
    // The MaterialObject contract address.
    address public materialObject;
    // The EmissionLogic contract address.
    address public emissionLogic;
    // The address used for Gelato Relay.
    address public gelatoRelay;
    // The address of the treasury.
    address payable public treasuryAddress;

    /// @notice Status:the coupon is used by msg sender
    uint256 private constant _CLAIMED = 1;

    // The fee to be paid for claiming a material object.
    uint256 public claimFee;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    // Mapping to track how many claims a sender has made.
    mapping(address => uint256) public claimedCount;
    // Mapping to track how many of each token a sender has claimed.
    mapping(address => mapping(uint256 => uint256)) public claimedEachCount;
    // Mapping to track the claim status of a sender for a specific event and logic ID.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public dailyClaimedStatus;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event emitted when the admin signer is set.
    event SetAdminSigner(address oldAdminSigner, address indexed newAdminSigner);
    // Event emitted when the MaterialObject contract is set.
    event SetMaterialObject(address oldMaterialContract, address indexed newMaterialContract);
    // Event emitted when the EmissionLogic contract is set.
    event SetEmissionLogic(address oldEmissionLogic, address indexed newEmissionLogic);
    // Event emitted when the GelatoRelay address is set.
    event SetGelatoRelay(address oldGelatoRelay, address indexed newGelatoRelay);
    // Event emitted when a user claims a material object.
    event LogClaimMaterialObject(address indexed sender, uint256 eventId, uint256 logicId, uint256 tokenId);
    // Event emitted when a claim is made by a relayer
    event ClaimedByRelayer(uint32 eventId, uint16 logicId, address relayer);
    // Event emitted when the treasury address is set.
    event SetTreasuryAddress(address payable treasuryAddress);
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // Error thrown if the user has already claimed an object with a given event ID and logic ID.

    error AlreadyClaimed(address sender, uint256 eventId, uint256 logicId);
    // Error thrown if the function call is not made by an admin.
    error NotAdminCall(address sender);
    // Error thrown if the ECDSA signature is invalid.
    error InvalidECDSASignature(address sender, address signer, bytes32 digest, Coupon coupon);
    // Error thrown if the coupon is invalid.
    error InvalidCoupon();
    // Error thrown if the lengths of the input arrays do not match.
    error ArrayLengthMismatch();
    // Error thrown if an address is invalid.
    error InvalidAddress(string reason);
    // Error thrown if the function call is not made by an GelatoRelay.
    error OnlyGelatoRelay();
    // Error thrown if the signature is expired.
    error SignatureExpired();
    // Error thrown if not smart contract
    error MustBeAContract();
    // Error thrown if the given coupons for batch claim are duplicated
    error DuplicatedCoupons();
    // Error thrown if the fee is invalid
    error InvalidFee();
    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor(
        address payable _treasuryAddress,
        address _adminSigner,
        address _materialObject,
        address _emissionLogic,
        address trustedForwarder,
        address _gelatoRelay
    )
        ERC2771Context(trustedForwarder)
    {
        if (_treasuryAddress == address(0)) revert InvalidAddress("treasuryAddress can't be 0");
        if (_adminSigner == address(0)) revert InvalidAddress("adminSigner can't be 0");
        if (_materialObject == address(0)) revert InvalidAddress("materialObject address can't be 0");
        if (_emissionLogic == address(0)) revert InvalidAddress("emissionLogic address can't be 0");
        if (_gelatoRelay == address(0)) revert InvalidAddress("gelatoRelay address can't be 0");

        treasuryAddress = _treasuryAddress;
        adminSigner = _adminSigner;
        materialObject = _materialObject;
        emissionLogic = _emissionLogic;
        gelatoRelay = _gelatoRelay;
        claimFee = 0.05 ether;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    // Modifier to ensure the user has not already claimed.
    modifier onlyIfNotClaimed(uint256 eventId, uint256 logicId) {
        if (dailyClaimedStatus[_msgSender()][eventId][logicId] == _CLAIMED) {
            revert AlreadyClaimed({ sender: _msgSender(), eventId: eventId, logicId: logicId });
        }
        _;
    }

    // Modifier to ensure none of the IDs in the arrays have already been claimed.
    modifier onlyIfNotClaimedMultiple(uint32[] memory eventIds, uint16[] memory logicIds) {
        uint256 length = eventIds.length;
        if (length != logicIds.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < length;) {
            if (dailyClaimedStatus[_msgSender()][eventIds[i]][logicIds[i]] == _CLAIMED) {
                revert AlreadyClaimed({ sender: _msgSender(), eventId: eventIds[i], logicId: logicIds[i] });
            }
            unchecked {
                ++i;
            }
        }
        _;
    }

    modifier nonDuplicatedCoupons(Coupon[] memory coupons) {
        for (uint256 i; i < coupons.length; i++) {
            if (coupons.hasDuplicate()) {
                revert DuplicatedCoupons();
            }
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Coupon                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Set a new admin signer
    function setAdminSigner(address _adminSigner) external onlyOwner {
        if (_adminSigner == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }

        address oldAdminSigner = adminSigner;
        adminSigner = _adminSigner;
        emit SetAdminSigner(oldAdminSigner, adminSigner);
    }

    /// @dev Check that the coupon sent was signed by the admin signer
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
        address signer = coupon.recover(digest);
        if (signer == address(0)) {
            revert InvalidECDSASignature({ sender: _msgSender(), signer: signer, digest: digest, coupon: coupon });
        }
        return signer == adminSigner;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   MUTATORS                                 */
    /* -------------------------------------------------------------------------- */
    function _checkSize(address addr) private view returns (uint256 extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }

    /// @dev Set a new EmissionLogic contract
    function setEmissionLogic(address _emissionLogic) external onlyOwner {
        if (_emissionLogic == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        if (_checkSize(_emissionLogic) == 0) revert MustBeAContract();

        address oldEmissionLogic = emissionLogic;
        emissionLogic = _emissionLogic;
        emit SetEmissionLogic(oldEmissionLogic, emissionLogic);
    }

    /// @dev Set a new MaterialObject contract
    function setMaterialObject(address _materialObject) external onlyOwner {
        if (_materialObject == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        if (_checkSize(_materialObject) == 0) revert MustBeAContract();

        address oldMaterialObject = materialObject;
        materialObject = _materialObject;
        emit SetMaterialObject(oldMaterialObject, materialObject);
    }

    /// @dev Set a new GelatoRelay contract
    function setGelatoRelay(address _gelatoRelay) external onlyOwner {
        if (_gelatoRelay == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        if (_checkSize(_gelatoRelay) == 0) revert MustBeAContract();
        address oldGelatoRelay = gelatoRelay;
        gelatoRelay = _gelatoRelay;
        emit SetGelatoRelay(oldGelatoRelay, gelatoRelay);
    }

    // Function to set the treasury address.
    function setTreasuryAddress(address payable newTreasuryAddress) external onlyOwner {
        if (newTreasuryAddress == address(0)) revert InvalidAddress("Treasury address can't be zero address");
        treasuryAddress = newTreasuryAddress;
        emit SetTreasuryAddress(newTreasuryAddress);
    }

    // Function to update the claim fee.
    function updateFee(uint256 newClaimFee) external onlyOwner {
        claimFee = newClaimFee;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                                 History                                    */
    /* -------------------------------------------------------------------------- */

    // Internal function to update claim status
    function _updateClaimStatus(address user, uint256 eventId, uint256 tokenId, uint256 logicId) internal {
        ++claimedCount[user];
        ++claimedEachCount[user][tokenId];
        dailyClaimedStatus[user][eventId][logicId] = _CLAIMED;
    }

    // Function to check the total number of claims made by a user.
    function checkClaimCount(address sender) external view returns (uint256) {
        return claimedCount[sender];
    }

    // Function to check the total number of claims made by a user for a specific token.
    function checkClaimEachCount(address sender, uint256 tokenId) external view returns (uint256) {
        return claimedEachCount[sender][tokenId];
    }

    // Function to check the claim status for a user for a specific event and logic ID.
    function checkClaimStatus(address sender, uint256 eventId, uint256 logicId) external view returns (uint256) {
        return dailyClaimedStatus[sender][eventId][logicId];
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Claim                                    */
    /* -------------------------------------------------------------------------- */
    // Function to process claim for material object
    function _processClaim(uint32 eventId, uint16 logicId, Coupon memory coupon, uint256 expiresIn) private {
        // Check that the coupon sent was signed by the admin signer
        bytes32 digest = keccak256(abi.encode(eventId, logicId, _msgSender(), expiresIn));
        if (!_isVerifiedCoupon(digest, coupon)) {
            revert InvalidCoupon();
        }

        uint256 tokenId = IEmissionLogic(emissionLogic).determineTokenByLogic(logicId);

        _updateClaimStatus(_msgSender(), eventId, tokenId, logicId);
        emit LogClaimMaterialObject(_msgSender(), eventId, logicId, tokenId);
        IMaterialObject(materialObject).getObject(_msgSender(), tokenId, 1);
    }

    // Function to claim a material object.
    function claimMaterialObject(
        uint32 eventId,
        uint16 logicId,
        Coupon memory coupon,
        uint256 expiresIn
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyIfNotClaimed(eventId, logicId)
    {
        if (msg.value != claimFee) revert InvalidFee();
        if (expiresIn <= block.timestamp) {
            revert SignatureExpired();
        }
        _processClaim(eventId, logicId, coupon, expiresIn);
        (bool sent,) = treasuryAddress.call{ value: claimFee }("");
        require(sent, "Failed to send Matic");
    }

    // Function to claim multiple material objects.
    function batchClaimMaterialObject(
        uint32[] memory eventIds,
        uint16[] memory logicIds,
        Coupon[] memory coupons,
        uint256 expiresIn
    )
        external
        payable
        nonReentrant
        whenNotPaused
        nonDuplicatedCoupons(coupons)
        onlyIfNotClaimedMultiple(eventIds, logicIds)
    {
        if (msg.value != eventIds.length * claimFee) revert InvalidFee();
        if (expiresIn <= block.timestamp) {
            revert SignatureExpired();
        }

        uint256 length = eventIds.length;
        // Ensure input arrays have the same length
        if (length != logicIds.length || logicIds.length != coupons.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < length;) {
            _processClaim(eventIds[i], logicIds[i], coupons[i], expiresIn);
            {
                ++i;
            }
        }
        (bool sent,) = treasuryAddress.call{ value: claimFee }("");
        require(sent, "Failed to send Matic");
    }

    /* -------------------------------------------------------------------------- */
    /*                               RelayClaim                                   */
    /* -------------------------------------------------------------------------- */
    modifier onlyGelatoRelay() {
        if (!_isGelatoRelay(msg.sender)) revert OnlyGelatoRelay();
        _;
    }

    function _isGelatoRelay(address _forwarder) internal view returns (bool) {
        return _forwarder == gelatoRelay;
    }

    // Function to claim a material object by relayer.
    function claimMaterialObjectByRelayer(
        uint32 eventId,
        uint16 logicId,
        Coupon memory coupon,
        uint256 expiresIn
    )
        external
        nonReentrant
        whenNotPaused
        onlyGelatoRelay
        onlyIfNotClaimed(eventId, logicId)
    {
        if (expiresIn <= block.timestamp) {
            revert SignatureExpired();
        }

        _processClaim(eventId, logicId, coupon, expiresIn);
        // Emit an event indicating that this function was called by a relayer
        emit ClaimedByRelayer(eventId, logicId, msg.sender);
    }

    // Function to claim multiple material objects by relayer.
    function batchClaimMaterialObjectByRelayer(
        uint32[] memory eventIds,
        uint16[] memory logicIds,
        Coupon[] memory coupons,
        uint256 expiresIn
    )
        external
        nonReentrant
        whenNotPaused
        onlyGelatoRelay
        nonDuplicatedCoupons(coupons)
        onlyIfNotClaimedMultiple(eventIds, logicIds)
    {
        if (expiresIn <= block.timestamp) {
            revert SignatureExpired();
        }

        uint256 length = eventIds.length;
        // Ensure input arrays have the same length
        if (length != logicIds.length || logicIds.length != coupons.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < length;) {
            _processClaim(eventIds[i], logicIds[i], coupons[i], expiresIn);
            emit ClaimedByRelayer(eventIds[i], logicIds[i], msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Context                                   */
    /* -------------------------------------------------------------------------- */
    // Both Pausable that inherits from Context and ERC2771Context have the same function _msgSender() and _msgData().
    // We need to override both functions to avoid the name conflict.
    function _msgSender() internal view override(ERC2771Context, Context) returns (address) {
        if (_isGelatoRelay(msg.sender)) {
            return ERC2771Context._msgSender();
        } else {
            return Context._msgSender();
        }
    }

    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        if (_isGelatoRelay(msg.sender)) {
            return ERC2771Context._msgData();
        } else {
            return Context._msgData();
        }
    }
}
