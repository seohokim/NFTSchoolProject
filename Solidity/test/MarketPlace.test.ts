import { ethers, network } from "hardhat";
import { expect } from "chai";

import { Signer, Contract, ContractFactory } from "ethers";

describe("MarketPlace Testing", function () {
    let UtilFactory : ContractFactory;
    let Util : Contract;
    let NFTImplementationFactory : ContractFactory;
    let NFTImplementation : Contract;
    let PendingQueueFactory : ContractFactory;
    let PendingQueueInst : Contract;
    let MarketPlaceFactory : ContractFactory;
    let MarketPlaceInst : Contract;

    let PendingQueue;
    let MarketPlace;
    let Governance;

    let owner : Signer;
    let minter : Signer;
    let burner : Signer;
    let user1 : Signer;
    let user2 : Signer;
    let others : Signer[];

    beforeEach(async function () {
        // First Deploying Util library
        UtilFactory = await ethers.getContractFactory('Util');
        Util = await UtilFactory.deploy();

        // Deploying NFT Implementation contract
        [owner, minter, burner, user1, user2, ...others] = await ethers.getSigners();
        NFTImplementationFactory = await ethers.getContractFactory('NFTImplementation', {
            libraries: {
                'Util': Util.address,
            }
        });
        NFTImplementation = await NFTImplementationFactory.connect(owner).deploy(minter.getAddress());
        PendingQueue = await NFTImplementation.pdQueueCon();
        MarketPlace = await NFTImplementation.marketPlace();
        Governance = await NFTImplementation.governance();

        PendingQueueFactory = await ethers.getContractFactory('PendingQueue');
        PendingQueueInst = await PendingQueueFactory.attach(PendingQueue);
    
        MarketPlaceFactory = await ethers.getContractFactory('MarketPlace');
        MarketPlaceInst = await MarketPlaceFactory.attach(MarketPlace);
    });

    it("#deposit()", async function () {
        await NFTImplementation.connect(user1).depositToMarket(1000);
        expect(await MarketPlaceInst.getUserBalanceOnMarket(user1.getAddress())).to.equal(1000);
    });

    it("#withdraw()", async function () {
        await NFTImplementation.connect(user1).depositToMarket(1000);
        await NFTImplementation.connect(user1).withdrawFromMarket(500);
        expect(await MarketPlaceInst.getUserBalanceOnMarket(user1.getAddress())).to.equal(500);
    });

    it("#makeMarket()", async function () {
        await expect(
            MarketPlaceInst.connect(owner).makeMarket(0x1)
        ).to.be.emit(MarketPlaceInst, "MarketCreated");
    });

    it("#openMarket()", async function () {
        await expect(
            MarketPlaceInst.connect(user1).openMarket(0x1)
        ).to.be.revertedWith("You are not owner");
        await MarketPlaceInst.connect(owner).makeMarket(0x1);
        await expect(
            MarketPlaceInst.connect(owner).openMarket(0x1)
        ).to.be.emit(MarketPlaceInst, "MarketOpened");
        await expect(
            MarketPlaceInst.connect(owner).openMarket(0x3)
        ).to.be.revertedWith("Market is not exists, create first!");
    });

    it("#closeMarket()", async function () {
        await MarketPlaceInst.connect(owner).makeMarket(0x1);
        await MarketPlaceInst.connect(owner).openMarket(0x1);
        await expect(
            MarketPlaceInst.connect(owner).closeMarket(0x2)
        ).to.be.revertedWith("Market is not opened");
        await expect(
            MarketPlaceInst.connect(owner).closeMarket(0x1)
        ).to.be.emit(MarketPlaceInst, "MarketClosed");
        const result = await MarketPlaceInst.market(0x1);
        expect(result.isOpened).to.equal(false);
    });

    it("#removeMarket()", async function () {
        // TODO
    });

    it("#startAuction()", async function () {
        // TODO
    });

    it("#endAuction()", async function () {
        // TODO
    });

    it("#suggest()", async function () {
        // TODO
    });
});