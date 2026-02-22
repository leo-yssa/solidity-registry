## solidity-registry

### 목적
재사용 가능한 Solidity 컨트랙트 모듈(`contracts/standard/**` 등)과, 이를 기반으로 한 구현체/프리셋, 테스트를 한 저장소에서 관리합니다.

### 디렉토리
- `contracts/standard/`: 라이브러리(베이스/믹스인/민터/공용 에러)
- `contracts/implementations/`: `standard` 모듈을 조합한 배포 가능한 구현체/프리셋
  - `contracts/implementations/standard/StandardPresetMinimal.sol`: 최소 프리셋
  - `contracts/implementations/standard/StandardPresetFull.sol`: 풀 프리셋(여러 믹스인 조합)
  - `contracts/implementations/chainlink/ChainlinkPresetMinimal.sol`: RevealMinter 호환 최소 프리셋
- `contracts/mocks/`: Hardhat 테스트용 목업
- `test/`: Hardhat 테스트

### 개발/테스트
의존성 설치:

```bash
npm install
```

테스트:

```bash
npm test
```

### 배포용 lib (implementations)
`contracts/implementations/**` 프리셋을 **직접 배포할 수 있도록**, 컨트랙트 bytecode + constructor args를 합쳐 `txData`를 만들고,
서명 가능한 EIP-1559 Deploy 트랜잭션을 구성하는 헬퍼를 제공합니다.

- `src/lib/deploy/implementations.ts`: 프리셋 deploy 트랜잭션 생성
- `src/lib/transaction/transaction.ts`: `makeTx`, `makeDeployTx`

예시(외부 RPC에서 deploy tx 만들기):

```ts
import { Wallet, ethers } from 'ethers';
import { makeImplementationDeployTx } from '@modernlion/solidity-registry';

const rpcUrl = process.env.RPC_URL!;
const pk = process.env.PRIVATE_KEY!;

const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
const signer = new Wallet(pk, provider);

const tx = await makeImplementationDeployTx(
  'StandardPresetMinimal',
  ['MyNFT', 'MNFT', 1000, 'https://example.com/metadata/'],
  provider,
  await signer.getAddress(),
);

const signed = await signer.signTransaction(tx);
const receipt = await (await provider.sendTransaction(signed)).wait();
console.log('deployed at', receipt.contractAddress);
```

#### 참고(Chainlink + OZ import)
`@chainlink/contracts`가 `@openzeppelin/contracts@4.9.6/...` 형태로 import하는 파일이 있어,
`npm install` 시 `scripts/postinstall.cjs`가 `node_modules/@openzeppelin/contracts@4.9.6` 별칭을 자동 생성합니다.

