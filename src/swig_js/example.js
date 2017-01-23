var wallycore = require('./build/Release/wallycore');

console.log(wallycore.wally_sha256(new Buffer('test', 'ascii')).toString('hex'));
