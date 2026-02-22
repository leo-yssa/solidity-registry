import { ethers } from 'ethers';

import { SolidityRegistryError } from '../exception';

export function getJsonRpcProvider(
  providerOrUrl: string | ethers.providers.JsonRpcProvider,
): ethers.providers.JsonRpcProvider {
  if (typeof providerOrUrl === 'string') return new ethers.providers.JsonRpcProvider(providerOrUrl);
  if (providerOrUrl instanceof ethers.providers.JsonRpcProvider) return providerOrUrl;
  throw new SolidityRegistryError(new Error('Invalid provider or URL provided.'));
}

