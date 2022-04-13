// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {IMetadataRenderer} from "../interfaces/IMetadataRenderer.sol";
import {ERC721Drop} from "../ERC721Drop.sol";

/// @notice Add ZORF NFT Style Fee Support
contract DropMetadataRenderer is IMetadataRenderer {
    struct MetadataURIInfo {
        string base;
        string extension;
        string contractURI;
        uint256 freezeAt;
    }

    modifier requireSenderAdmin(address target) {
        require(
            target == msg.sender || ERC721Drop(target).isAdmin(msg.sender),
            "Only admin"
        );

        _;
    }

    mapping(address => MetadataURIInfo) public metadataBaseByContract;

    function initializeWithData(bytes memory data) external {
        // data format: target, baseURI, newContractURI
        (string memory initialBaseURI, string memory initialContractURI) = abi.decode(data, (string, string));
        _updateMetadataDetails(msg.sender, initialBaseURI, "", initialContractURI, 0);
    }

    function onMint(address minter, uint256 tokenId) external {}

    function updateMetadataBase(
        address target,
        string memory baseUri,
        string memory newContractURI
    ) external requireSenderAdmin(target) {
        _updateMetadataDetails(target, baseUri, "", newContractURI, 0);
    }

    function updateMetadataBaseWithDetails(
        address target,
        string memory metadataBase,
        string memory metadataExtension,
        string memory newContractURI,
        uint256 freezeAt
    ) public requireSenderAdmin(target) {
        _updateMetadataDetails(
            target,
            metadataBase,
            metadataExtension,
            newContractURI,
            freezeAt
        );
    }

    function _updateMetadataDetails(
        address target,
        string memory metadataBase,
        string memory metadataExtension,
        string memory newContractURI,
        uint256 freezeAt
    ) internal {
        require(freezeAt == 0 || freezeAt < block.timestamp, "Metadata frozen");
        metadataBaseByContract[target] = MetadataURIInfo({
            base: metadataBase,
            extension: metadataExtension,
            contractURI: newContractURI,
            freezeAt: freezeAt
        });
    }

    function contractURI() external view override returns (string memory) {
        return metadataBaseByContract[msg.sender].contractURI;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        MetadataURIInfo memory info = metadataBaseByContract[msg.sender];

        return
            string(
                abi.encodePacked(
                    info.base,
                    StringsUpgradeable.toString(tokenId),
                    info.extension
                )
            );
    }
}