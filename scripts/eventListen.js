const { ethers } = require('ethers');
const axios = require('axios');
const { MongoClient } = require('mongodb');

// Connection URL
const url = 'mongodb://localhost:27017';
// Database Name
const dbName = 'yourDatabaseName';
// Contract Address
const contractAddress = 'YOUR_CONTRACT_ADDRESS';
// Contract ABI
const abi = [ /* Your Contract ABI */ ];
// Provider URL
const providerUrl = 'YOUR_FUJI_CCHAIN_RPC_URL';
const provider = new ethers.providers.JsonRpcProvider(providerUrl);

// Connection to the contract
const contract = new ethers.Contract(contractAddress, abi, provider);

// Cronjob Interval in milliseconds (5 minutes)
const interval = 5 * 60 * 1000;

async function main() {
  const client = new MongoClient(url);
  try {
    await client.connect();
    const db = client.db(dbName);

    // Call this function every 5 minutes
    setInterval(async () => {
      const lastBlockNumber = await getLastBlockNumber(db);

      // Fetch new logs from the contract
      const logs = await contract.queryFilter('*', lastBlockNumber + 1);
      
      for (const log of logs) {
        if (log.event === 'Buy') {
          const amount = log.args[0].toString(); // assuming the amount is the first argument in the event
          const user = log.args[1]; // assuming the user is the second argument in the event
          const currency = log.args[2]; // assuming the currency is the third argument in the event
          
          // Get the conversion rate
          const response = await axios.get(`https://min-api.cryptocompare.com/data/price?fsym=${currency}&tsyms=INR&api=b5baa8a285ba5b72a8e23bf83c9df6767b1c2a3f0cc29112052eb6e81ad9eb62`);
          const rate = response.data.INR;
          const amountInINR = amount * rate;

          // Save the event data to MongoDB
          await db.collection('events').insertOne({
            blockNumber: log.blockNumber,
            transactionHash: log.transactionHash,
            user,
            amount,
            currency,
            amountInINR
          });

          // Update the last read block number
          await updateLastBlockNumber(db, log.blockNumber);
        }
      }
    }, interval);
  } catch (error) {
    console.error(error);
  }
}

async function getLastBlockNumber(db) {
  const data = await db.collection('metadata').findOne({ key: 'lastBlockNumber' });
  return data ? data.value : 0; // replace 0 with the block number from which you want to start reading events
}

async function updateLastBlockNumber(db, blockNumber) {
  await db.collection('metadata').updateOne({ key: 'lastBlockNumber' }, { $set: { value: blockNumber } }, { upsert: true });
}

main();
