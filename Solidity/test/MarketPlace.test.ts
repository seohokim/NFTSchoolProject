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

    });

    it("#openMarket()", async function () {

    });

    it("#closeMarket()", async function () {

    });

    it("#removeMarket()", async function () {

    });
});