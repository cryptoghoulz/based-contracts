usePlugin("@nomiclabs/buidler-waffle");

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

require('dotenv').config();
const privateKey = process.env.DEV1_PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const INFURA_ID = process.env.INFURA_ID;

// You have to export an object to set up your config
// This object can have the following optional entries:
// defaultNetwork, networks, solc, and paths.
// Go to https://buidler.dev/config/ to learn more
module.exports = {
  defaultNetwork: "localhost",
  networks: {
    buidlerevm: {
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_ID}`,
      accounts: [`0x${privateKey}`]
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_ID}`,
      accounts: [`0x${privateKey}`]
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_ID}`,
      accounts: [`0x${privateKey}`]
    }
  },
  solc: {
    version: "0.4.24",
    optimizer: {
      enabled: false,
      runs: 200
    }
  },

  paths: {
    sources: "./contracts/v4",
  },
};
