import { ethers } from "hardhat";
import { expect } from "chai";

import { Signer, Contract, ContractFactory } from "ethers";

describe("NFT Contract testing", function () {
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

    it("#mint()", async function () {
        await NFTImplementation.connect(minter).mint(user1.getAddress(), {
            unique_id: 0x1234
        });
        expect(await NFTImplementation.connect(minter).ownerOf(0x1234)).to.equal(await user1.getAddress());
    });

    it("#burningByAdmin()", async function () {
        await NFTImplementation.connect(minter).mint(user1.getAddress(), {
            unique_id: 0x1234
        });
        await NFTImplementation.connect(owner).burningByAdmin(0x1234);
        // TokenID is removed, thus it will be reverted.
        await expect(NFTImplementation.ownerOf(0x1234)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("#requestBurning()", async function () {
        await NFTImplementation.connect(minter).mint(user1.getAddress(), {
            unique_id: 0x1234
        });
        await NFTImplementation.connect(user1).requestBurning(0x1234);
        const result = await PendingQueueInst.pendingQueue(0);
        expect(result.id).to.equal(0x1234);
        expect(result.owner).to.equal(await user1.getAddress());
    });

    it("#transferOwnership()", async function () {
        await NFTImplementation.connect(minter).mint(user1.getAddress(), {
            unique_id: 0x1234
        });
        await NFTImplementation.connect(user1).transferOwnership(user2.getAddress(), 0x1234);
        expect(await NFTImplementation.ownerOf(0x1234)).to.equal(await user2.getAddress());

        // Second, we need to check metadata information for each user
        const result_1 = await NFTImplementation.isExists(user1.getAddress(), 0x1234);
        const result_2 = await NFTImplementation.isExists(user2.getAddress(), 0x1234);
        expect(result_1).to.equal(false);
        expect(result_2).to.equal(true);
    });
});