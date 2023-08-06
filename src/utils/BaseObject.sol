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

import { IERC2981 } from "@openzeppelin/interfaces/IERC2981.sol";
import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";

import { MultiOwner } from "./MultiOwner.sol";

/**
 * @dev Contracts to manage Objects.
 */
abstract contract BaseObject is MultiOwner, IERC2981, ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    string public name;
    string public symbol;
    string public baseMetadataURI;

    /* -------------------------------- ROYALTIES ------------------------------- */
    address public shopAddress;
    address payable public treasuryAddress;
    /// @notice get for primary market ratio.
    uint256 public royalityFee;
    /// @notice get for second market ratio.
    uint256 public secondaryRoyalty;
    uint256 public paymentBalanceOwner;

    uint256 private constant _MAX_ROYALITY_FEE = 5000;
    uint256 private constant _MAX_SECONDARY_ROYALITY_FEE = 2000;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- OBJECT -------------------------------- */
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    struct Object {
        string tokenURI;
        Size size;
        address payable creator;
        uint256 maxClaimable;
        uint256 price;
        uint256 exp;
        bool forSale;
    }

    mapping(uint256 => Object) public allObjects;
    mapping(uint256 => bool) public created;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event SetbaseMetadataURI(string baseuri);
    event SetMaxClaimed(uint256 tokenId, uint256 newMaxClaimed);
    event SetExp(uint256 tokenId, uint256 exp);
    event SetTokenURI(uint256 tokenId, string uri);
    event SetSize(uint256 tokenId, uint8 x, uint8 y, uint8 z);
    event SetCreator(uint256 tokenId, address payable creator);
    event SetOpenForSale(uint256 tokenId, bool check);
    event ChangeTokenPrice(uint256 tokenId, uint256 newPrice);
    event SetShopAddress(address shopAddress);
    event SetRoyalityFee(uint256 royalityFee);
    event SetSecondaryRoyalityFee(uint256 secondaryRoyalty);
    event SetTreasuryAddress(address payable treasuryAddress);
    event PaymentWithdrawnOwner(uint256 amount);
    event PaymentReceivedOwner(uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidTokenID();
    error ExistentToken();
    error NotSetTokenSize();
    error PaymentBalanceZero();
    // Error to throw if an input address is invalid.
    error InvalidAddress(string reason);
    error InvalidRoyaltyFee(uint256 value);
    error InvalidSecondaryRoyalityFee(uint256 value);

    /* -------------------------------------------------------------------------- */
    /*                                   OBJECT                                   */
    /* -------------------------------------------------------------------------- */
    /* Utility Functions */

    function _isValid(uint256 tokenId) internal view virtual {
        // Validate that the token is within range when querying
        if (!created[tokenId]) revert InvalidTokenID();
    }

    /* --------------------------------- SETTER --------------------------------- */
    function setbaseMetadataURI(string memory newBaseMetadataURI) external onlyOwner {
        baseMetadataURI = newBaseMetadataURI;
        emit SetbaseMetadataURI(newBaseMetadataURI);
    }

    function setTreasuryAddress(address payable newTreasuryAddress) external onlyOwner {
        if (newTreasuryAddress == address(0)) revert InvalidAddress("Treasury address can't be zero address");
        treasuryAddress = newTreasuryAddress;
        emit SetTreasuryAddress(newTreasuryAddress);
    }

    function setMaxClaimable(uint256 tokenId, uint256 newMaxClaimable) public virtual onlyOwner {
        allObjects[tokenId].maxClaimable = newMaxClaimable;
        emit SetMaxClaimed(tokenId, newMaxClaimable);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public virtual onlyOwner {
        allObjects[tokenId].tokenURI = uri;
        emit SetTokenURI(tokenId, uri);
    }

    function setSize(uint256 tokenId, Size memory size) public virtual onlyOwner {
        allObjects[tokenId].size = size;
        emit SetSize(tokenId, size.x, size.y, size.z);
    }

    function setExp(uint256 tokenId, uint256 exp) public virtual onlyOwner {
        allObjects[tokenId].exp = exp;
        emit SetExp(tokenId, exp);
    }

    function setCreatorAddress(uint256 tokenId, address payable creator) public virtual onlyOwner {
        if (creator == address(0)) revert InvalidAddress("Creator address can't be zero address");
        allObjects[tokenId].creator = creator;
        emit SetCreator(tokenId, creator);
    }

    function setOpenForSale(uint256 tokenId, bool check) public virtual onlyOwner {
        allObjects[tokenId].forSale = check;
        emit SetOpenForSale(tokenId, check);
    }

    function changeTokenPrice(uint256 tokenId, uint256 newPrice) public onlyOwner {
        allObjects[tokenId].price = newPrice;
        emit ChangeTokenPrice(tokenId, newPrice);
    }

    function setShopAddress(address _shopAddress) external onlyOwner {
        if (_shopAddress == address(0)) revert InvalidAddress("Shop address can't be zero address");
        shopAddress = _shopAddress;
        emit SetShopAddress(shopAddress);
    }

    /* --------------------------------- GETTER --------------------------------- */

    function getMaxClaimed(uint256 tokenId) external view returns (uint256) {
        return allObjects[tokenId].maxClaimable;
    }

    function getExp(uint256 tokenId) external view returns (uint256) {
        return allObjects[tokenId].exp;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return allObjects[tokenId].tokenURI;
    }

    function getSize(uint256 tokenId) external view returns (Size memory) {
        if (allObjects[tokenId].size.x == 0 || allObjects[tokenId].size.y == 0) revert NotSetTokenSize();
        return allObjects[tokenId].size;
    }

    function getCreatorAddress(uint256 tokenId) external view returns (address payable) {
        return allObjects[tokenId].creator;
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        return allObjects[tokenId].price;
    }

    function getOpenForSale(uint256 tokenId) external view returns (bool) {
        return allObjects[tokenId].forSale;
    }

    function getObjectInfo(uint256 tokenId) external view returns (Object memory) {
        return allObjects[tokenId];
    }

    /* -------------------------------------------------------------------------- */
    /*                                  ROYALTIES                                 */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice EIP2981 royalty standard
    function royaltyInfo(
        uint256,
        uint256 salePrice
    )
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (salePrice * secondaryRoyalty) / 10_000;
        return (receiver, royaltyAmount);
    }

    /// @notice Receive royalties
    receive() external payable {
        _addToOwnerBalance(msg.value);
    }

    /// @notice Adds funds to the payment balance for the owner.
    /// @param amount The amount to add to the balance.
    function _addToOwnerBalance(uint256 amount) internal {
        paymentBalanceOwner += amount;
        emit PaymentReceivedOwner(amount);
    }

    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Set primary market ratio.
    // The initial mint-time share ratio with the creator.
    function setRoyalityFee(uint256 newRoyalityFee) external onlyOwner {
        if (newRoyalityFee > _MAX_ROYALITY_FEE) {
            revert InvalidRoyaltyFee(newRoyalityFee);
        }
        royalityFee = newRoyalityFee;
        emit SetRoyalityFee(newRoyalityFee);
    }

    function setSecondaryRoyalityFee(uint256 newSecondaryRoyalty) external onlyOwner {
        if (newSecondaryRoyalty > _MAX_SECONDARY_ROYALITY_FEE) {
            revert InvalidSecondaryRoyalityFee(newSecondaryRoyalty);
        }
        secondaryRoyalty = newSecondaryRoyalty;
        emit SetSecondaryRoyalityFee(newSecondaryRoyalty);
    }

    /// @notice Sends you your full available balance.
    /// @param withdrawTo The address to send the balance to.
    function withdrawOwnerBalance(address withdrawTo) external onlyOwner nonReentrant {
        if (withdrawTo == address(0)) revert InvalidAddress("Withdraw address can't be zero address");
        if (paymentBalanceOwner == 0) revert PaymentBalanceZero();
        uint256 balance = paymentBalanceOwner;
        paymentBalanceOwner = 0;

        (bool success,) = withdrawTo.call{ value: balance }("");
        if (!success) revert PaymentBalanceZero();

        emit PaymentWithdrawnOwner(balance);
    }
}
