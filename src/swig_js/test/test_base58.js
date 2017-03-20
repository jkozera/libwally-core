var wally = require('../wally');
var test = require('tape');

test('base58 from bytes', function(t) {
  var cases = [];
  // Leading zeros become ones
  for (var i = 1; i < 10; ++i) {
    var ones = '';
    for (var j = 0; j < i; ++j) ones += '1';
    cases.push([[new Uint8Array(i), 0], ones])
  }
  cases.push([[new Buffer('00CEF022FA', 'hex'), 0], '16Ho7Hs']);
  cases.push([[new Buffer('45046252208D', 'hex'), 1], '4stwEBjT6FYyVV']);

  t.plan(cases.length);
  cases.forEach(function(testCase) {
    wally.wally_base58_from_bytes(
      testCase[0][0], testCase[0][1]
    ).then(function(s) {
      t.equal(s, testCase[1],
        'base58_from_bytes('+
        new Buffer(testCase[0][0]).toString('hex')+','+testCase[0][1]+')');
    });
  });
});
