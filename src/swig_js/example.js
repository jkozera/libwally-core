var wally = require('./wally');

wally.wally_sha256(new Buffer('test', 'ascii')).then(function(uint8Array) {
  console.log(new Buffer(uint8Array).toString('hex'))
});
wally.wally_base58_from_bytes(new Buffer('xyz', 'ascii'), 0).then(function(s) {
  console.log(s);
  wally.wally_base58_to_bytes(s, 0).then(function(bytes_) {
    console.log(new Buffer(bytes_).toString('ascii'));
  });
})
