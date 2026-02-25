import { concat, hexlify, Interface } from 'ethers';
import type { TransactionRequest } from 'ethers';

import { SolidityRegistryError } from '../exception';
import { makeDeployTx } from '../transaction/transaction';
import { ArtifactLike, readHardhatArtifact } from './hardhatArtifact';

export const IMPLEMENTATION_CONTRACTS = {
  StandardPresetMinimal: {
    contractName: 'StandardPresetMinimal',
    defaultEstimateGas: 6_500_000,
  },
  StandardPresetFull: {
    contractName: 'StandardPresetFull',
    defaultEstimateGas: 7_000_000,
  },
  ChainlinkPresetMinimal: {
    contractName: 'ChainlinkPresetMinimal',
    defaultEstimateGas: 6_800_000,
  },
} as const;

export type ImplementationContractName = keyof typeof IMPLEMENTATION_CONTRACTS;

export type StandardLikePresetConstructorArgs = [string, string, bigint | number, string];

export async function buildDeployTxData(
  contractName: string,
  constructorArgs: unknown[],
  artifact?: ArtifactLike,
): Promise<string> {
  try {
    const a = artifact ?? (await readHardhatArtifact(contractName));
    const iface = new Interface(a.abi);
    const encoded = iface.encodeDeploy(constructorArgs);
    return hexlify(concat([a.bytecode, encoded]));
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

export async function makeImplementationDeployTx(
  implementation: ImplementationContractName,
  args: StandardLikePresetConstructorArgs,
  providerOrUrl: string | import('ethers').JsonRpcProvider,
  executorAddress: string,
  estimateGas?: number,
  artifact?: ArtifactLike,
): Promise<TransactionRequest> {
  const info = IMPLEMENTATION_CONTRACTS[implementation];
  const txData = await buildDeployTxData(info.contractName, args, artifact);
  return await makeDeployTx(txData, providerOrUrl, estimateGas ?? info.defaultEstimateGas, executorAddress);
}

