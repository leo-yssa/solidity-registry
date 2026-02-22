import '@nomiclabs/hardhat-ethers';
import '@typechain/hardhat';
import '@nomicfoundation/hardhat-chai-matchers';
import 'solidity-coverage';
import 'hardhat-gas-reporter';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.19',
        settings: {
          optimizer: { enabled: true, runs: 200 },
          viaIR: true,
        },
      },
      {
        version: '0.8.17',
        settings: {
          optimizer: { enabled: true, runs: 200 },
          viaIR: true,
        },
      },
      { version: '0.4.26' },
    ],
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: {
        accountsBalance: '1000000000000000000000',
        count: 200,
      },
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined
          ? [
              String(process.env.PRIVATE_KEY),
              String(process.env.PRIVATE_KEY2),
              String(process.env.PRIVATE_KEY3),
              String(process.env.PRIVATE_KEY4),
            ]
          : [],
    },
    polygon: {
      url: process.env.POLYGON_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined
          ? [
              String(process.env.PRIVATE_KEY),
              String(process.env.PRIVATE_KEY2),
              String(process.env.PRIVATE_KEY3),
              String(process.env.PRIVATE_KEY4),
            ]
          : [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined
          ? [
              String(process.env.PRIVATE_KEY),
              String(process.env.PRIVATE_KEY2),
              String(process.env.PRIVATE_KEY3),
              String(process.env.PRIVATE_KEY4),
            ]
          : [],
    },
  },
  typechain: {
    outDir: 'lib/interfaces',
  },
};

export default config;
