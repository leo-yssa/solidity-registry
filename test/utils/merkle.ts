import { keccak256, solidityPackedKeccak256 } from 'ethers';
import { MerkleTree } from 'merkletreejs';

// Contract uses keccak256(abi.encodePacked(msg.sender))
function hashLeaf(address: string): Buffer {
  const hex = solidityPackedKeccak256(['address'], [address]);
  return Buffer.from(hex.slice(2), 'hex');
}

function hashBuffer(data: Buffer): Buffer {
  const hex = keccak256('0x' + data.toString('hex'));
  return Buffer.from(hex.slice(2), 'hex');
}

export function buildMerkleTree(addresses: string[]) {
  const leaves = addresses.map(hashLeaf);
  const tree = new MerkleTree(leaves, hashBuffer, { sortPairs: true });
  return { tree, leaves };
}

export function getProof(tree: MerkleTree, address: string) {
  const leaf = hashLeaf(address);
  return tree.getHexProof(leaf);
}

