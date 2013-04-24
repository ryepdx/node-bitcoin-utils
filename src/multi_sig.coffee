Crypto = require('crypto')
BigNum = require('bignum')
Base58 = require('base58')

hash = (algo, data) ->
    Crypto.createHash(algo).update(data).digest("binary")

bytesToInt = (bytes) ->
    intVal = 0
    for i in [(bytes.length - 1)..0]
        intVal = (intVal * 256) + bytes[i]
    return intVal

bigIntegerFromByteArray = (bytes) ->
    if bytes.length
        if bytes[0] & 128
            return new BigInteger([0].concat(bytes))
        else
            new BigInteger(bytes)
    else
        bytes.valueOf(0)

decodeHex = (hex) ->
    val = BigNum('0')
    hexchars = "0123456789ABCDEF"
    hex = hex.toUpperCase()
    
    for char in hex
        val = val.mul(16).add(hexchars.indexOf(char))
    return val

encodeBase58 = (hex) ->
    base58chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    
    if hex.length % 2 != 0
        throw "encodeBase58: uneven number of hex characters";
 
    orighex = hex;

    intVal = decodeHex(hex)
    base58Val = ""
    
    while intVal.gt(0)
        div = intVal.div(58)
        rem = intVal.mod(58)
        intVal = div
        base58Val += base58chars.charAt(rem)
 
    base58Val = base58Val.split("").reverse().join("")
    
    index = 0
    
    while index < orighex.length and orighex.substr(index, 2) == "00"
        base58Val = "1" + base58Val
        index += 2

    return base58Val

strToBytes = (str) ->
    bytes = []
    for chr in str
        bytes.push(chr.charCodeAt(0))
    return bytes

bytesToHex = (bytes) ->
    hex = ''
    for byte in bytes
        chr = byte.toString(16)
        if chr.length < 2
            hex += '0' + chr
        else
            hex += chr
    return hex

hexToBytes = (hex) ->
    bytes = []
    for i in [0..(hex.length-1)] by 2
        bytes.push(parseInt(hex.substr(i, 2), 16))
    return bytes
    
strToHex = (str) ->
    bytesToHex strToBytes(str)

createMultiSig = (nReq, keys) ->
    if nReq >= 2 and nReq <= 16
        rs = [0x50 + nReq]
        
        for key in keys
            bpk = hexToBytes key
            rs.push(bpk.length)
            
            for b in bpk
                rs.push(b)
            
        rs.push(0x50 + keys.length)
        rs.push(0xAE)
        midHashed = "\x05" + hash("ripemd160", hash("sha256", String.fromCharCode.apply(String, rs)))
        hashed = hash("sha256", hash("sha256", midHashed))
        addrInt = strToHex(midHashed + hashed.substr(0, 4))
        
        return {
            redeemScript: bytesToHex rs
            address: encodeBase58 addrInt
        }
