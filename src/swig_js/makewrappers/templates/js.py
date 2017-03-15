TEMPLATE = '''
try {
    var window = global.window || {};
} catch (e) { var window = {}; }

module.exports = {};

if (window.cordova) {
    var base64 = require('base64-js');

    module.exports.wally_hex_from_bytes = function (uintArray) {
        return uintArray.reduce(function (hex, i) {
            return hex + (i < 16 ? '0' : '') + i.toString(16);
        }, '');
    };

    !!list_of_cordova_funcs!!
} else {
    var wallycore = require('./build/Release/wallycore');
    // nodejs
    !!list_of_nodejs_funcs!!
}

'''

def _generate_cordovajs(funcname, func):
    args = []
    for i, arg in enumerate(func.arguments):
        if isinstance(arg, tuple):
            pass
        else:
            if arg.startswith('const_bytes'):
                args.append('base64.fromByteArray(_arguments[%s])' % i)
            elif arg.startswith('uint32_t'):
                args.append('_arguments[%s]' % i)
    return '''
        module.exports.%s = function () {
            var _arguments = arguments;
            return new Promise(function (resolve, reject) {
                window.cordova.exec(
                    function (res) { resolve(new Uint8Array(res)); },  // FIXME only for bytes
                    reject, 'Wally', '%s', [%s]
                );
            });
        };
    ''' % (funcname, funcname, ', '.join(args))


def _generate_nodejs(funcname, func):
    return '''
        module.exports.%s = function () {
            var _arguments = [];
            _arguments.push.apply(_arguments, arguments);
            _arguments.push(null);
            return Promise.resolve(
                new Uint8Array(wallycore.%s.apply(wallycore, _arguments))
            );
        }
    ''' % (funcname, funcname)


def generate(functions):
    list_of_cordova_funcs = []
    list_of_nodejs_funcs = []
    for funcname, f in functions:
        list_of_cordova_funcs.append(_generate_cordovajs(funcname, f))
        list_of_nodejs_funcs.append(_generate_nodejs(funcname, f))
    return TEMPLATE.replace(
        '!!list_of_cordova_funcs!!',
        '\n\n'.join(list_of_cordova_funcs)
    ).replace(
        '!!list_of_nodejs_funcs!!',
        '\n\n'.join(list_of_nodejs_funcs)
    )
    return TEMPLATE
