import type { TransactionRequest } from 'ethers';
import { getJsonRpcProvider } from '../utils/provider';

import { SolidityRegistryError } from '../exception';
import { convertPriceToBigNumber } from '../utils/payment';
import { getFeeData } from '../utils/gasFee';

export async function makeTx(
  txData: string,
  providerOrUrl: string | import('ethers').JsonRpcProvider,
  estimateGas: number,
  etherValue: string,
  executorAddress: string,
  contractAddress: string,
): Promise<TransactionRequest> {
  try {
    const jsonRpcProvider = getJsonRpcProvider(providerOrUrl);
    const feeData = await getFeeData(providerOrUrl);
    const network = await jsonRpcProvider.getNetwork();

    return {
      to: contractAddress,
      value: convertPriceToBigNumber(etherValue, 18),
      data: txData,
      gasLimit: BigInt(estimateGas),
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas ?? undefined,
      maxFeePerGas: feeData.maxFeePerGas ?? undefined,
      nonce: await jsonRpcProvider.getTransactionCount(executorAddress),
      type: 2,
      chainId: network.chainId,
    };
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

export async function makeDeployTx(
  txData: string,
  providerOrUrl: string | import('ethers').JsonRpcProvider,
  estimateGas: number,
  executorAddress: string,
): Promise<TransactionRequest> {
  try {
    const jsonRpcProvider = getJsonRpcProvider(providerOrUrl);
    const feeData = await getFeeData(providerOrUrl);
    const network = await jsonRpcProvider.getNetwork();

    return {
      data: txData,
      value: convertPriceToBigNumber('0', 18),
      gasLimit: BigInt(estimateGas),
      maxPriorityFeePerGas: feeData.maxPriorityFeePerGas ?? undefined,
      maxFeePerGas: feeData.maxFeePerGas ?? undefined,
      nonce: await jsonRpcProvider.getTransactionCount(executorAddress),
      type: 2,
      chainId: network.chainId,
    };
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

/**
 * increase maxFeePerGas and maxPriorityFeePerGas.
 * increase unit is 1%
 */
export function increaseGas(percent: number, transaction: TransactionRequest): TransactionRequest {
  const mul = (v: bigint | undefined) =>
    v === undefined ? undefined : (v * BigInt(100 + percent)) / BigInt(100);
  return {
    ...transaction,
    maxPriorityFeePerGas: mul(
      transaction.maxPriorityFeePerGas !== undefined ? BigInt(transaction.maxPriorityFeePerGas.toString()) : undefined,
    ),
    maxFeePerGas: mul(
      transaction.maxFeePerGas !== undefined ? BigInt(transaction.maxFeePerGas.toString()) : undefined,
    ),
    type: 2,
  };
}

