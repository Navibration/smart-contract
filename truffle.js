module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      from: "0xDAFe44a41294cCe0656f29c77bCCBDeF8de34f5f",
      gas: 4700000
    }
  },
  solc: { optimizer: { enabled: true, runs: 200 } }
}
