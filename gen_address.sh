#!/bin/bash 

# Short script hack to generate off-the-grid EC private key and 
# BOTH the corresponding Bitcoin and Namecoin addresses.
#
# Use on offline computers to create cold, deep storage solutions. 
#
# No guarantees are given or implied. USE AT YOUR OWN RISK!
# Based on botg.sh. v0.0.1.

# Adapted from the script at http://dot-bit.org/forum/viewtopic.php?f=9&t=779
# Credit goes to moa for writing the original version.

base58=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
coinregex="^[$(printf "%s" "${base58[@]}")]{34}$"

PRIVKEY='/dev/shm/data.pem'

decodeBase58() {
    local s=$1
    for i in {0..57}
    do s="${s//${base58[i]}/ $i}"
    done
    dc <<< "16o0d${s// /+58*}+f" 
}

encodeBase58() {
    # 58 = 0x3A
    bc <<<"ibase=16; n=${1^^}; while(n>0) { n%3A ; n/=3A }" |
    tac |
    while read n
    do echo -n ${base58[n]}
    done
}

checksum() {
    xxd -p -r <<<"$1" |
    openssl dgst -sha256 -binary |
    openssl dgst -sha256 -binary |
    xxd -p -c 80 |
    head -c 8
}

checkBitcoinAddress() {
    if [[ "$1" =~ $coinregex ]]
    then
        h=$(decodeBase58 "$1")
        checksum "00${h::${#h}-8}" |
        grep -qi "^${h: -8}$"
    else return 2
    fi
}

hash160() {
    openssl dgst -sha256 -binary |
    openssl dgst -rmd160 -binary |
    xxd -p -c 80
}

hash160ToBtcAddress() {
    printf "%34s\n" "$(encodeBase58 "00$1$(checksum "00$1")")" |
    sed "y/ /1/"
}

publicKeyToBtcAddress() {
    hash160ToBtcAddress $(
    openssl ec -pubin -pubout -outform DER |
    tail -c 65 |
    hash160
    )
}

publicKeyToHex() {
    openssl ec -pubout -in ${PRIVKEY} -outform DER |
    tail -c 65 |
    hexdump -e '1/1 "%02X"'
}

hash256ToAddress() {   
   #printf "80$1$(checksum "80$1")"
    printf "%34s\n" "$(encodeBase58 "80$1$(checksum "80$1")")" |
    sed "y/ /1/"
}

privateKeyToWIF() {
    hash256ToAddress $(openssl ec -text -noout -in ${PRIVKEY} | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g')
}

generateKey() {
    openssl  ecparam -genkey -name secp256k1 | tee ${PRIVKEY} &>/dev/null

    hexsize=$(openssl ec -text -noout -in ${PRIVKEY} | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g' ) 

    while [ ${#hexsize} -ne 64 ]
    do
    openssl  ecparam -genkey -name secp256k1 | tee ${PRIVKEY} &>/dev/null && hexsize=$(openssl ec -text -noout -in ${PRIVKEY} | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g' ) 
    done

    openssl ec -text -noout -in ${PRIVKEY} | head -5 | tail -3 | fmt -120 | sed 's/[: ]//g' > /dev/null

    btc_address=$(openssl ec -pubout -in ${PRIVKEY} | publicKeyToBtcAddress)

    checkBitcoinAddress

    # Save the private and public Bitcoin keys.
    privateKeyToWIF > ${btc_address}.key
    publicKeyToHex > ${btc_address}.pub
}

for ((i=0;i<${1-1};i++))
do
    generateKey 
done

# overwrite key file with a new key and remove from memory.
openssl ecparam -genkey -name secp256k1 | tee ${PRIVKEY} &>/dev/null && rm ${PRIVKEY}

exit 0
