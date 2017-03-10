
TEMPLATE = '''import Wally

@objc(CDVWally) class CDVWally : CDVPlugin {
    !!swift_cases!!
}'''


def _generate_swift(funcname, f):
    input_args = []
    output_args = []
    args = []
    postprocess = []
    for i, arg in enumerate(f.arguments):
        if isinstance(arg, tuple):
            output_args.append(
                'let resultSwift = [UInt8](repeating: 0, count: %s);'
                'let resultPtr = UnsafeMutablePointer<UInt8>(mutating: resultSwift);' % arg[1])
            args.append('resultPtr')
            args.append(str(arg[1]))
            postprocess.append('let result = resultSwift.map({ (i) -> NSValue in return NSNumber(value: i) })');
        else:
            if arg.startswith('const_bytes'):
                input_args.append(
                    '''let array_%s_B64 = command.argument(at: %s) as! NSString as String;
                    let array_%s_Data = NSData(
                        base64Encoded: array_%s_B64, options: NSData.Base64DecodingOptions.init(rawValue: 0));
                    let array_%s = [UInt8](repeating: 0, count: array_%s_Data!.length);
                    array_%s_Data?.getBytes(
                        UnsafeMutableRawPointer(mutating: array_%s),
                        range: NSRange(location: 0, length: array_%s_Data!.length));
                    let array_%s_Ptr = UnsafeMutablePointer<UInt8>(mutating: array_%s);'''  % tuple(
                        [i]*11
                    )
                )
                args.append('array_%s_Ptr' % i)
                args.append('array_%s_Data!.length' % i)
            elif arg.startswith('uint32_t'):
                args.append('command.argument(at: %s) as! UInt32' % i)
    return ('''
        func %s(_ command: CDVInvokedUrlCommand) {
            !!input_args!!
            !!output_args!!
            Wally.%s(!!args!!);
            !!postprocess!!
            let pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: result
            )
            commandDelegate!.send(
                pluginResult, callbackId:command.callbackId
            )
        }
    ''' % (funcname, funcname)).replace(
        '!!input_args!!', '\n'.join(input_args)
    ).replace(
        '!!output_args!!', '\n'.join(output_args)
    ).replace(
        '!!args!!', ', '.join(args)
    ).replace(
        '!!postprocess!!', '\n'.join(postprocess)
    )


def generate(functions):
    swift_cases = []
    for i, (funcname, f) in enumerate(functions):
        swift_cases.append(_generate_swift(funcname, f))
    return TEMPLATE.replace(
        '!!swift_cases!!',
        ''.join(swift_cases)
    )
