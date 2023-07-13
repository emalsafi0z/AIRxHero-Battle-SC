const { expect } = require("chai");

describe("BettingGame", function () {
  let game;
  let link;
  let vrfCoordinator;

  let player1;
  let player2;

  beforeEach(async function () {
    const BettingGameFactory = await ethers.getContractFactory("BettingGame");
    const LinkTokenFactory = await ethers.getContractFactory("LinkToken");

    game = await BettingGameFactory.deploy(
      vrfCoordinator.address,
      link.address,
      "YOUR_KEY_HASH",
      ethers.utils.parseEther("0.1")
    );
    link = await LinkTokenFactory.deploy();
    vrfCoordinator = await ethers.getSigner();

    player1 = await ethers.getSigner(1);
    player2 = await ethers.getSigner(2);

    // Mint ERC721 tokens for player1 and player2
    const ERC721Factory = await ethers.getContractFactory("ERC721");
    const nftContract = await ERC721Factory.deploy("NFT", "NFT");
    await nftContract.deployed();
    await nftContract.mint(player1.address, 1);
    await nftContract.mint(player2.address, 2);

    // Approve the game contract to transfer the NFTs on behalf of the players
    await nftContract.connect(player1).setApprovalForAll(game.address, true);
    await nftContract.connect(player2).setApprovalForAll(game.address, true);
  });

  it("should create an arena and join the arena successfully", async function () {
    await game.connect(player1).createArena(1);
    await game.connect(player2).joinArena(1);

    const arena = await game.arenas(1);

    expect(arena.player1).to.equal(player1.address);
    expect(arena.player2).to.equal(player2.address);
    expect(arena.totalValue).to.equal(2);
    expect(arena.isFinished).to.equal(true);
  });

  it("should not allow non-NFT holders to create an arena", async function () {
    await expect(game.connect(player2).createArena(1)).to.be.revertedWith("You must be an NFT holder to create an arena");
  });

  it("should not allow joining a non-existing arena", async function () {
    await expect(game.connect(player2).joinArena(1)).to.be.revertedWith("Arena does not exist for this NFT");
  });

  // Add more test cases as needed
});