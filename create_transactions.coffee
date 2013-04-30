bitcoin = require 'bitcoin'
config = require './config.json'
fs = require 'fs'
lazy = require 'lazy'

exports.BitcoinClient = new bitcoin.Client(config.host, config.port, config.username, config.password)

exports.createTransactionFromLine = (line, cb) ->
    # Creates a transaction from a string containing the sending and receiving
    # addresses, as well as the amount to send.
    # Expected line format:
    # <sending address> <receiving address> <amount>
    # Each sending address should have a private key file in the keyDir.
    
    line = line.split ' '
    fs.readFile(config.keyDir + line[0] + '.key', 'utf8', (err, data) ->
        txnDetails = {}
        txnDetails[line[1]] = parseInt line[2]
        
        inputs = []
        for txnID in line[3..]
            inputs.push { txid: txnID, vout: 0}
        
        exports.BitcoinClient.createRawTransaction inputs, txnDetails, (err, txn) ->
            exports.BitcoinClient.signRawTransaction txn, [], [data], (err, signedTxn) ->
                cb signedTxn.hex
    )

# Was this passed a command line argument?
# If so, run it like a command line utility.
if process.argv.length > 2

    # Grab each line in the passed-in file and create transactions in the
    # txnDir directory specified in config.json.
    file = new lazy fs.createReadStream(process.argv[2])
    file.lines.forEach (line) ->
        line = line.toString()
        exports.createTransactionFromLine line, (txn) ->
            fs.writeFile config.txnDir + line.replace(/\ /g, '_') + '.txn', txn
