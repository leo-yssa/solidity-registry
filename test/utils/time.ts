import { ethers } from 'hardhat';

export async function setNextBlockTimestamp(ts: number) {
  await ethers.provider.send('evm_setNextBlockTimestamp', [ts]);
  await ethers.provider.send('evm_mine', []);
}

export async function latestTimestamp(): Promise<number> {
  const b = await ethers.provider.getBlock('latest');
  return b.timestamp;
}

