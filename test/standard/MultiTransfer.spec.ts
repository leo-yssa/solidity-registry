import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('MultiTransfer', () => {
  it('reverts if msg.value != sum(recipients)', async () => {
    const [owner, r1, r2] = await ethers.getSigners();
    const MultiTransfer = await ethers.getContractFactory('MultiTransfer', owner);
    const mt = await MultiTransfer.deploy();
    await mt.waitForDeployment();

    const recipients = [
      { receiver: r1.address, amount: ethers.parseEther('0.01') },
      { receiver: r2.address, amount: ethers.parseEther('0.02') },
    ];

    await expect(
      mt.multiTransfer(recipients, { value: ethers.parseEther('0.02') })
    ).to.be.revertedWithCustomError(mt, 'IncorrectPayment');
  });

  it('reverts when recipient is a contract', async () => {
    const [owner, eoa] = await ethers.getSigners();
    const MultiTransfer = await ethers.getContractFactory('MultiTransfer', owner);
    const mt = await MultiTransfer.deploy();
    await mt.waitForDeployment();

    const Receiver = await ethers.getContractFactory('PayableReceiver', owner);
    const receiver = await Receiver.deploy();
    await receiver.waitForDeployment();

    const recipients = [
      { receiver: eoa.address, amount: ethers.parseEther('0.01') },
      { receiver: await receiver.getAddress(), amount: ethers.parseEther('0.01') },
    ];

    await expect(
      mt.multiTransfer(recipients, { value: ethers.parseEther('0.02') })
    ).to.be.revertedWithCustomError(mt, 'RecipientIsContract');
  });

  it('sends funds to multiple EOAs', async () => {
    const [owner, r1, r2] = await ethers.getSigners();
    const MultiTransfer = await ethers.getContractFactory('MultiTransfer', owner);
    const mt = await MultiTransfer.deploy();
    await mt.waitForDeployment();

    const a1 = ethers.parseEther('0.01');
    const a2 = ethers.parseEther('0.02');

    const b1 = await ethers.provider.getBalance(r1.address);
    const b2 = await ethers.provider.getBalance(r2.address);

    await mt.multiTransfer(
      [
        { receiver: r1.address, amount: a1 },
        { receiver: r2.address, amount: a2 },
      ],
      { value: a1 + a2 }
    );

    expect((await ethers.provider.getBalance(r1.address)) - b1).to.eq(a1);
    expect((await ethers.provider.getBalance(r2.address)) - b2).to.eq(a2);
  });
});

