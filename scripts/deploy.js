const { artifacts, ethers, upgrades } = require('hardhat')
const getNamedSigners = require('../utils/getNamedSigners')
const saveToConfig = require('../utils/saveToConfig')
const readFromConfig = require('../utils/readFromConfig')
const deploySettings = require('./deploySettings')

async function main () {

  const chainId = await hre.getChainId()
  console.log("STARTING AUTOLIMITXSWAP DEPLOYMENT ON ", chainId)

  const CHAIN_NAME = deploySettings[chainId].CHAIN_NAME
  
  const CONNEXT_ADDRESS = deploySettings[chainId].CONNEXT_ADDRESS
  const LINK_TOKEN_ADDRESS = deploySettings[chainId].LINK_TOKEN_ADDRESS
  const WETH_ADDRESS = deploySettings[chainId].WETH_ADDRESS
  const SWAP_ROUTER_ADDRESS = deploySettings[chainId].SWAP_ROUTER_ADDRESS
  const UPKEEPER_REGISTRAR_ADDRESS = deploySettings[chainId].UPKEEPER_REGISTRAR_ADDRESS
  const NATIVE_ADDRESS = deploySettings[chainId].NATIVE_ADDRESS


  console.log('Deploying autoLimitXSwap Smart Contract')
  const {payDeployer} =  await getNamedSigners();

  const AUTOLIMITXSWAP_CONTRACT = await ethers.getContractFactory('AutoLimitXSwap')
  AUTOLIMITXSWAP_CONTRACT.connect(payDeployer)


  const ABI = (await artifacts.readArtifact('AutoLimitXSwap')).abi
  await saveToConfig(`AUTOLIMITXSWAP_${CHAIN_NAME}`, 'ABI', ABI)

  const autoLimitXSwapDeployer = await AUTOLIMITXSWAP_CONTRACT.deploy(
    CONNEXT_ADDRESS,
    SWAP_ROUTER_ADDRESS,
    LINK_TOKEN_ADDRESS,
    UPKEEPER_REGISTRAR_ADDRESS,
    WETH_ADDRESS,
    NATIVE_ADDRESS
  )
  await autoLimitXSwapDeployer.deployed()

  await saveToConfig(`AUTOLIMITXSWAP_${CHAIN_NAME}`, 'ADDRESS', autoLimitXSwapDeployer.address)
  console.log('AutoLimitXSwap contract deployed to:', autoLimitXSwapDeployer.address, ` on ${CHAIN_NAME}`)

  await new Promise((resolve) => setTimeout(resolve, 40 * 1000));
  console.log('Verifying Contract...')

  try {
    await run('verify:verify', {
      address: autoLimitXSwapDeployer.address || "0xDCD300706887ac0E4d69433c3a5C2E75ED7F3c34",
      contract: 'contracts/AutoLimitXSwap.sol:AutoLimitXSwap', // Filename.sol:ClassName
      constructorArguments: [
        CONNEXT_ADDRESS,
        SWAP_ROUTER_ADDRESS,
        LINK_TOKEN_ADDRESS,
        UPKEEPER_REGISTRAR_ADDRESS,
        WETH_ADDRESS,
        NATIVE_ADDRESS
      ],
      network: deploySettings[chainId].NETWORK_NAME
    })
  } catch (error) {
    console.log(error)
  }

}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
