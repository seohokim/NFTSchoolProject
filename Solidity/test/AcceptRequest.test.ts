import { ethers } from "hardhat";
import { expect } from "chai";

import { time } from "@nomicfoundation/hardhat-network-helpers";

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
        await NFTImplementation.connect(user1).mint(
            user1.getAddress(), 
            {unique_id: 0x1},
            {value: ethers.utils.parseEther('0.001')});
        const DepositPoolBalance = await ethers.provider.getBalance(DepositPool.address);

        expect(DepositPoolBalance).to.equal(ethers.utils.parseEther('0.001'));
        // Check minted token
        expect(await NFTImplementation.ownerOf(0x1)).to.equal(await user1.getAddress());
        const afterMinting = await ethers.provider.getBalance(user1.getAddress());
        // Call requestBurning()
        await NFTImplementation.connect(user1).requestBurning(0x1);
        // Check Pending Queue
        expect(await PendingQueueInst.findPendingMetadata(0x1)).to.equal(0x0);
        // Change current block timestamp ( + 10 days)
        await time.increase(60 * 60 * 24 * 10);
        // Call acceptRequest()
        await NFTImplementation.connect(owner).acceptRequest();
        // Check Pending Queue
        expect(await PendingQueueInst.findPendingMetadata(0x1)).not.to.equal(0x0);
        expect(await ethers.provider.getBalance(DepositPool.address)).to.equal(0);
        const afterBurning = await ethers.provider.getBalance(user1.getAddress());

        expect(afterBurning).greaterThan(afterMinting);
        await expect(NFTImplementation.ownerOf(0x1)).to.be.revertedWith("ERC721: invalid token ID");
    });
});