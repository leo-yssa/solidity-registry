import { SolidityRegistryError } from '../exception';

export type ArtifactLike = {
  abi: any;
  bytecode: string;
};

export async function readHardhatArtifact(contractName: string): Promise<ArtifactLike> {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const hre = require('hardhat') as { artifacts: { readArtifact(name: string): Promise<ArtifactLike> } };
    return await hre.artifacts.readArtifact(contractName);
  } catch (e) {
    throw new SolidityRegistryError(
      e instanceof Error
        ? e
        : new Error(
            `Failed to load Hardhat artifact for "${contractName}". Make sure you run this inside a Hardhat runtime (or pass an artifact explicitly).`,
          ),
    );
  }
}

