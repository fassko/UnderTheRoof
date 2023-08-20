import { ethers } from "hardhat";

async function main() {
  const [owner, person1, person2] = await ethers.getSigners();

  const UnderTheRoof = await ethers.getContractFactory("UnderTheRoof");
  console.log("\nDeploying UnderTheRoof contract");

  const underTheRoof = await UnderTheRoof.deploy();
  await underTheRoof.waitForDeployment();

  console.log("🕸 UnderTheRoof contract address: ", await underTheRoof.target);

  // Register property
  console.log("Registering to ", person1.address);
  await underTheRoof.registerProperty(
    person1.address,
    "https://www.kv.ee/kinnisvara/uusarendused/kaseke-tahe-19-tartu-6039"
  );

  console.log("Owner of 1", await underTheRoof.ownerOf(1));

  // Sell
  // console.log("Buyer:", person2.address);
  const weiAmount = ethers.toBigInt(1000);
  const ethAmount = ethers.formatEther(weiAmount);

  await underTheRoof.connect(person2).deposit({
    value: weiAmount,
  });

  await underTheRoof
    .connect(person1)
    .sellProperty(person2.address, 1, weiAmount);

  console.log("New owner", await underTheRoof.ownerOf(1));

  // Rent
  // await underTheRoof.connect(person1).startRenting(1, 1000);

  // console.log(await underTheRoof.rentals(1));

  // await underTheRoof.connect(person2).rentNFT(1, { value: weiAmount });

  // console.log(await underTheRoof.rentals(1));

  // await underTheRoof.connect(person2).returnNFT(1);

  // console.log(await underTheRoof.rentals(1));

  // await underTheRoof.connect(person1).stopRenting(1);

  // console.log(await underTheRoof.rentals(1));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
