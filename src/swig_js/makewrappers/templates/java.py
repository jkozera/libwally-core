TEMPLATE = '''package com.blockstream.libwally;

import java.nio.charset.Charset;

import android.util.Base64;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

public class WallyCordova extends CordovaPlugin {
    @Override
    public boolean execute(
            final String action, final JSONArray args,
            final CallbackContext callbackContext) throws JSONException {

        !!java_cases!!

        return true;
    }
}
'''


def _generate_java(funcname, f):
    input_args = []
    output_args = []
    args = []
    for i, arg in enumerate(f.arguments):
        if isinstance(arg, tuple):
            output_args.append('byte[] res = new byte[%s];' % arg[1])
            args.append('res');
        else:
            if arg.startswith('const_bytes'):
                input_args.append(
                    'byte[] input%s = '
                    'Base64.decode(args.getString(%s), Base64.NO_WRAP);' % (
                        i, i
                    )
                )
                args.append('input%s' % i)
            elif arg.startswith('uint32_t'):
                args.append('args.getInt(%s)' % i)
    return ('''
        if (action.equals("%s")) {
            !!input_args!!
            !!output_args!!
            Wally.%s(!!args!!);
            PluginResult result = new PluginResult(PluginResult.Status.OK, res);
            callbackContext.sendPluginResult(result);
        }
    ''' % (funcname, funcname[len('wally_'):])).replace(
        '!!input_args!!', '\n'.join(input_args)
    ).replace(
        '!!output_args!!', '\n'.join(output_args)
    ).replace(
        '!!args!!', ', '.join(args)
    )


def generate(functions):
    java_cases = []
    for i, (funcname, f) in enumerate(functions):
        java_cases.append(_generate_java(funcname, f))
    return TEMPLATE.replace(
        '!!java_cases!!',
        ' else '.join(java_cases)
    )
