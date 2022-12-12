import { ethers, network } from "hardhat";
import { Signer, ContractFactory, Contract } from "ethers";

let UtilFactory : ContractFactory;
let Util : Contract;
let NFTImplementationFactory : ContractFactory;
let NFTImplementation : Contract;
let PendingQueueFactory : ContractFactory;
let PendingQueueInst : Contract;
let MarketPlaceFactory : ContractFactory;
let MarketPlaceInst : Contract;
let DepositPoolFactory : ContractFactory;
let DepositPool : Contract;

let PendingQueue;
let MarketPlace;
let Governance;

let owner : Signer;
let minter : Signer;
let burner : Signer;
let user1 : Signer;
let user2 : Signer;
let others : Signer[];

async function main() {
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
  // await Governance.addAllowedContract(NFTImplementation.address);

  PendingQueueFactory = await ethers.getContractFactory('PendingQueue');
  PendingQueueInst = await PendingQueueFactory.attach(PendingQueue);

  MarketPlaceFactory = await ethers.getContractFactory('MarketPlace');
  MarketPlaceInst = await MarketPlaceFactory.attach(MarketPlace);

  // Deploying DepositPool
  DepositPoolFactory = await ethers.getContractFactory('DepositPool', {libraries: {'Util': Util.address,}});
  DepositPool = await DepositPoolFactory.connect(owner).deploy(NFTImplementation.address);

  await NFTImplementation.connect(owner).setDepositPool(DepositPool.address);

  console.log(`NFTImplementation Address : ${NFTImplementation.address}`);
  console.log(`MarketPlace Address : ${MarketPlaceInst.address}`);

  // Make market marketID=1
  // Open market marketID=1
  await MarketPlaceInst.makeMarket(0x1);
  await MarketPlaceInst.openMarket(0x1);

  await MarketPlaceInst.makeMarket(0x2);
  await MarketPlaceInst.openMarket(0x2);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
