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
    });

    it("#deposit()", async function () {

    });

    it("#withdraw()", async function () {

    });
});