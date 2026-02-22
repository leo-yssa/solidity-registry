import { utils } from 'ethers';
import { MerkleTree } from 'merkletreejs';

export function buildMerkleTree(addresses: string[]) {
  const leaves = addresses.map((a) => utils.solidityKeccak256(['address'], [a]));
  const tree = new MerkleTree(leaves, utils.keccak256, { sortPairs: true });
  return { tree, leaves };
}

export function getProof(tree: MerkleTree, address: string) {
  const leaf = utils.solidityKeccak256(['address'], [address]);
  return tree.getHexProof(leaf);
}

