#!/bin/bash
while IFS= read line
do
    transaction=($line)
    priv_key=$(cat ${transaction[0]}.key)
    raw_transaction=$(bitcoind createrawtransaction \{${transaction[1]}:${transaction[2]}\})
    bitcoind signrawtransaction '$raw_transaction' '["$priv_key"]' > ${transaction[0]}_${transaction[1]}_${transaction[2]}_$2.txn
done < "$1"
