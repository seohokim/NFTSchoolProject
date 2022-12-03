import { ethers } from "hardhat";
import { expect } from "chai";

import { Signer, ContractFactory, Contract } from "ethers";

describe.only("AcceptRequest will return their deposits to each user", function () {
    let DepositPoolFactory : ContractFactory;
    let NFTImplementationFactory : ContractFactory;

    let DepositPool : Contract;
    let NFTImplementation : Contract;

    let UtilFactory : ContractFactory;
    let Util : Contract;
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

        // Deploying DepositPool
        DepositPoolFactory = await ethers.getContractFactory('DepositPool', {libraries: {'Util': Util.address,}});
        DepositPool = await DepositPoolFactory.connect(owner).deploy(NFTImplementation.address);

        await NFTImplementation.connect(owner).setDepositPool(DepositPool.address);
    });

    it("Deposited liqudity should return to each user", async function () {
    });
});