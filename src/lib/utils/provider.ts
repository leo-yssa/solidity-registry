import { JsonRpcProvider } from 'ethers';

import { SolidityRegistryError } from '../exception';

export function getJsonRpcProvider(providerOrUrl: string | JsonRpcProvider): JsonRpcProvider {
  if (typeof providerOrUrl === 'string') return new JsonRpcProvider(providerOrUrl);
  if (providerOrUrl instanceof JsonRpcProvider) return providerOrUrl;
  throw new SolidityRegistryError(new Error('Invalid provider or URL provided.'));
}

