import { BigNumber, ethers, Transaction } from 'ethers';

import { SolidityRegistryError } from '../exception';
import { convertPriceToBigNumber } from '../utils/payment';
import { getFeeData } from '../utils/gasFee';
import { getJsonRpcProvider } from '../utils/provider';

export async function makeTx(
  txData: string,
  providerOrUrl: string | ethers.providers.JsonRpcProvider,
  estimateGas: number,
  etherValue: string,
  executorAddress: string,
  contractAddress: string,
): Promise<Transaction> {
  try {
    const jsonRpcProvider = getJsonRpcProvider(providerOrUrl);
    const feeData = await getFeeData(providerOrUrl);
    const maxFeePerGas = feeData.maxFeePerGas;
    const maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;

    return {
      to: contractAddress,
      value: BigNumber.from(convertPriceToBigNumber(etherValue, 18)),
      data: txData,
      gasLimit: BigNumber.from(estimateGas),
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? undefined,
      maxFeePerGas: maxFeePerGas ?? undefined,
      nonce: await jsonRpcProvider.getTransactionCount(executorAddress),
      type: ethers.utils.TransactionTypes.eip1559,
      chainId: jsonRpcProvider.network.chainId,
    };
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

export async function makeDeployTx(
  txData: string,
  providerOrUrl: string | ethers.providers.JsonRpcProvider,
  estimateGas: number,
  executorAddress: string,
): Promise<Transaction> {
  try {
    const jsonRpcProvider = getJsonRpcProvider(providerOrUrl);
    const feeData = await getFeeData(providerOrUrl);
    const maxFeePerGas = feeData.maxFeePerGas;
    const maxPriorityFeePerGas = feeData.maxPriorityFeePerGas;

    return {
      data: txData,
      value: BigNumber.from(convertPriceToBigNumber('0', 18)),
      gasLimit: BigNumber.from(estimateGas),
      maxPriorityFeePerGas: maxPriorityFeePerGas ?? undefined,
      maxFeePerGas: maxFeePerGas ?? undefined,
      nonce: await jsonRpcProvider.getTransactionCount(executorAddress),
      type: ethers.utils.TransactionTypes.eip1559,
      chainId: jsonRpcProvider.network.chainId,
    };
  } catch (e) {
    throw new SolidityRegistryError(e);
  }
}

/**
 * increase maxFeePerGas and maxPriorityFeePerGas.
 * increase unit is 1%
 */
export function increaseGas(percent: number, transaction: Transaction): Transaction {
  return {
    to: transaction.to,
    value: transaction.value,
    data: transaction.data,
    gasLimit: transaction.gasLimit,
    maxPriorityFeePerGas: transaction.maxPriorityFeePerGas
      ? transaction.maxPriorityFeePerGas.mul(100 + percent).div(100)
      : undefined,
    maxFeePerGas: transaction.maxFeePerGas ? transaction.maxFeePerGas.mul(100 + percent).div(100) : undefined,
    nonce: transaction.nonce,
    type: ethers.utils.TransactionTypes.eip1559,
    chainId: transaction.chainId,
  };
}

