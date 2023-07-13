// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.9;
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BettingGame is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    struct Arena {
        address player1;
        address player2;
        uint256 randomSeed;
        uint256 totalValue;
        bool isFinished;
    }

    mapping(address => bool) public isNftHolder;
    mapping(uint256 => Arena) public arenas;

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    function createArena(uint256 _tokenId) external {
        require(isNftHolder[msg.sender], "You must be an NFT holder to create an arena");
        require(IERC721(msg.sender).ownerOf(_tokenId) == msg.sender, "You must own the NFT to create an arena");
        require(!isArenaExist(_tokenId), "Arena already exists for this NFT");

        arenas[_tokenId].player1 = msg.sender;
        arenas[_tokenId].totalValue += _tokenId;

        IERC721(msg.sender).transferFrom(msg.sender, address(this), _tokenId);
    }

    function joinArena(uint256 _tokenId) external {
        require(isNftHolder[msg.sender], "You must be an NFT holder to join an arena");
        require(IERC721(msg.sender).ownerOf(_tokenId) == msg.sender, "You must own the NFT to join an arena");
        require(isArenaExist(_tokenId), "Arena does not exist for this NFT");
        require(arenas[_tokenId].player2 == address(0), "Arena is already full");

        arenas[_tokenId].player2 = msg.sender;
        arenas[_tokenId].totalValue += _tokenId;

        IERC721(msg.sender).transferFrom(msg.sender, address(this), _tokenId);

        if (arenas[_tokenId].player1 != address(0) && arenas[_tokenId].player2 != address(0)) {
            startGame(_tokenId);
        }
    }

    function startGame(uint256 _tokenId) private {
        require(!arenas[_tokenId].isFinished, "Game has already finished");

        arenas[_tokenId].randomSeed = getRandomNumber();
        arenas[_tokenId].isFinished = true;

        uint256 randomNumber = arenas[_tokenId].randomSeed % 100;

        if (randomNumber < 50) {
            IERC721(msg.sender).transferFrom(address(this), msg.sender, arenas[_tokenId].totalValue);
        } else {
            IERC721(arenas[_tokenId].player1).transferFrom(address(this), arenas[_tokenId].player2, arenas[_tokenId].totalValue);
        }
    }

    function getRandomNumber() private returns (uint256) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens to fulfill randomness request");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
        // Use randomness as needed
    }

    function isArenaExist(uint256 _tokenId) public view returns (bool) {
        return arenas[_tokenId].player1 != address(0);
    }
}