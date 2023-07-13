// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract BattleGame is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event GameEnded(
        address _player1,
        uint256 _tokenId1,
        address _player2,
        uint256 _tokenId2
    );

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    struct Arena {
        address player1;
        address player2;
        uint256 tokenId1;
        uint256 tokenId2;
        bool isStarted;
    }

    mapping(uint256 => Arena) public arenas;
    // RequestId => ArenasId
    mapping(uint256 => uint256) internal arenasAndVRFmap;
    IERC721 public airxhero;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     */
    constructor(
        uint64 subscriptionId,
        address _airxhero
    )
        VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        s_subscriptionId = subscriptionId;

        airxhero = IERC721(_airxhero);
    }

    function createArena(uint256 _tokenId) external {
        require(
            airxhero.ownerOf(_tokenId) == msg.sender,
            "You must own the NFT to create an arena"
        );
        require(!isArenaExist(_tokenId), "Arena already exists for this NFT");

        arenas[_tokenId].isStarted = true;
        arenas[_tokenId].player1 = msg.sender;
        arenas[_tokenId].tokenId1 += _tokenId;

        airxhero.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function joinArena(uint256 _arenasId, uint256 _tokenId) external {
        require(
            airxhero.ownerOf(_tokenId) == msg.sender,
            "You must own the NFT to join an arena"
        );
        require(isArenaExist(_arenasId), "Arena does not exist for this NFT");
        require(
            arenas[_arenasId].player2 == address(0),
            "Arena is already full"
        );

        arenas[_arenasId].player2 = msg.sender;
        arenas[_arenasId].tokenId2 += _tokenId;

        airxhero.safeTransferFrom(msg.sender, address(this), _tokenId);

        if (
            arenas[_arenasId].player1 != address(0) &&
            arenas[_arenasId].player2 != address(0)
        ) {
            startGame(_arenasId);
        }
    }

    function startGame(uint256 _arenasId) private {
        require(arenas[_arenasId].isStarted, "Game has already finished");

        requestRandomness(_arenasId);
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomness(
        uint256 _arenasId
    ) private returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;

        arenasAndVRFmap[requestId] = _arenasId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        endGame(_requestId, _randomWords[0]);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function endGame(uint256 _requestId, uint256 _randomWord) internal {
        uint256 _arenasId = arenasAndVRFmap[_requestId];

        arenas[_arenasId].isStarted = false;

        address p1 = arenas[_arenasId].player1;
        uint256 t1 = arenas[_arenasId].tokenId1;
        address p2 = arenas[_arenasId].player2;
        uint256 t2 = arenas[_arenasId].tokenId2;

        uint256 randomNumber = _randomWord % 100;

        if (randomNumber < 50) {
            airxhero.safeTransferFrom(address(this), p1, t1);
        } else {
            airxhero.safeTransferFrom(address(this), p2, t2);
        }

        emit GameEnded(p1, t1, p2, t2);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function isArenaExist(uint256 _tokenId) public view returns (bool) {
        return arenas[_tokenId].isStarted;
    }
}
