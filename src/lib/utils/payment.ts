import { BigNumber, ethers } from 'ethers';

export const paymentType = {
  ETH: 'ETH',
  ERC20: 'ERC20',
} as const;
export type PaymentType = (typeof paymentType)[keyof typeof paymentType];

export function convertPriceToBigNumber(amount: string, decimals = 18): BigNumber {
  return ethers.utils.parseUnits(amount, decimals);
}

