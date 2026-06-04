/**
 * @title AEGIS Protocol Deployment Script
 * @notice Deploys AegisShield and AegisPool to Base network
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying AEGIS Protocol contracts...");
  console.log("Deployer:", deployer.address);
  console.log("Balance:", (await deployer.getBalance()).toString());
  
  // Deploy AegisShield
  console.log("\n Deploying AegisShield...");
  const AegisShield = await ethers.getContractFactory("AegisShield");
  const aegisShield = await AegisShield.deploy();
  await aegisShield.deployed();
  console.log("AegisShield deployed to:", aegisShield.address);
  
  // Deploy AegisPool
  console.log("\n Deploying AegisPool...");
  const AegisPool = await ethers.getContractFactory("AegisPool");
  const aegisPool = await AegisPool.deploy();
  await aegisPool.deployed();
  console.log("AegisPool deployed to:", aegisPool.address);
  
  console.log("\n=== DEPLOYMENT COMPLETE ===");
  console.log("AegisShield:", aegisShield.address);
  console.log("AegisPool:", aegisPool.address);
  console.log("===========================");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });