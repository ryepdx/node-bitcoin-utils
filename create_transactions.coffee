bitcoin = require 'bitcoin'
config = require './config.json'
fs = require 'fs'
lazy = require 'lazy'

exports.BitcoinClient = new bitcoin.Client(config.host, config.port, config.username, config.password)

exports.createTransaction = (fromAddress, toAddresses, fromTransactions,
privKeyCB, txnCB) ->
    # Creates a transaction using the specified transaction JSON and callbacks.
    # txnJSON must have a fromAddress string, a toAddresses array of objects,
    # and a fromTransactions array of transaction IDs.
    exports.BitcoinClient.createRawTransaction(fromTransactions, toAddresses, 
    (err, txn) ->
        if err
            console.log err
            
        privKeyCB fromAddress, (privKey) ->
            exports.BitcoinClient.signRawTransaction txn, [], [privKey], (err, signedTxn) ->
                if err
                    console.log err
                    
                txnCB signedTxn.hex
    )
    
# Was this passed a command line argument?
# If so, run it like a command line utility.
if process.argv.length > 2
    _signWithPrivateKey = (fromAddress, signTxn) ->
        fs.readFile(config.keyDir + fromAddress + '.key', 'utf8', (err, data) ->
            signTxn data
        )
            
    _saveSignedTransaction = (fromAddress)->
        return (signedTxn) ->
            fs.writeFile config.txnDir + fromAddress + '.txn', signedTxn

    # Grab each object in the passed-in JSON file and create transactions in the
    # txnDir directory specified in config.json.
    transactions = require process.argv[2]
    for fromAddress, transaction of transactions
        exports.createTransaction( fromAddress, transaction.toAddresses,
        transaction.fromTransactions, _signWithPrivateKey,
        _saveSignedTransaction(fromAddress))
