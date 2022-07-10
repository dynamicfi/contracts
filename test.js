const Web3 = require("web3")

const web3 = new Web3("https://data-seed-prebsc-1-s1.binance.org:8545/")

const DyBNBVenus = require("./artifacts/contracts/venus/DyBNBVenus.sol/DyBNBVenus.json")

async function test() {
  const venusContract = new web3.eth.Contract(
    DyBNBVenus.abi,
    "0xd9c9f3F63C7f0402A29047EA74D2E904011eF9e4"
  );
//   const res = await venusContract.methods.totalDeposits().call();
//   console.log("RES:", res);

  const ownerPrivateKey =
    "";
  const ownerAccount = web3.eth.accounts.privateKeyToAccount(ownerPrivateKey);
  web3.eth.accounts.wallet.add(ownerAccount);

  const amount = "1000000000000000";
  const transferFunc = venusContract.methods.deposit(amount);

  const gasEstimate = await transferFunc.estimateGas({
    from: ownerAccount.address,
    // value: 0
    value: amount
  });

  const resTranfer = await transferFunc.send({
    from: ownerAccount.address,
    gas: gasEstimate,
    // value: 0
    value: amount
  });
  console.log(`Deposit Success, txhash:${resTranfer.transactionHash}`);
}

test();