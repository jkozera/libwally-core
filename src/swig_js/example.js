var wally = require('./wally');

wally.wally_sha256(new Buffer('test', 'ascii')).then(function(uint8Array) {
  console.log(new Buffer(uint8Array).toString('hex'))
});
