import { ethers } from 'ethers';

import { SolidityRegistryError } from '../exception';
import { getJsonRpcProvider } from './provider';

export async function getFeeData(providerOrUrl: string | ethers.providers.JsonRpcProvider) {
  try {
    const provider = getJsonRpcProvider(providerOrUrl);
    return await provider.getFeeData();
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

export function calculateAirdropEstimateGas(amount: number): number {
  if (amount <= 1) return 200_000;
  if (amount <= 10) return 1_000_000;
  if (amount <= 50) return 4_000_000;
  return 7_000_000;
}

