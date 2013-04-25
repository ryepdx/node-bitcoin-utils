Crypto = require('crypto')
BigNum = require('bignum')

hash = (algo, data) ->
    Crypto.createHash(algo).update(data).digest("binary")

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
        
        addressStart = "\x05" + hash("ripemd160", hash("sha256", String.fromCharCode.apply(String, rs)))
        checksum = hash("sha256", hash("sha256", addressStart)).substr(0, 4)
        addressHex = strToHex(addressStart + checksum)
        
        return {
            redeemScript: bytesToHex rs
            address: encodeBase58 addressHex
        }

console.log(createMultiSig(2, ["0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86","04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874","048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213"]))
