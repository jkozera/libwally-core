TEMPLATE='''#include <nan.h>

extern "C" {
#include "../include/wally_core.h"
#include "../include/wally_bip32.h"
#include "bip32_int.h"
#include "../include/wally_bip38.h"
#include "../include/wally_bip39.h"
#include "../include/wally_crypto.h"
}

!!nan_impl!!

void Init(v8::Local<v8::Object> exports) {
    !!nan_decl!!
}

NODE_MODULE(wallycore, Init)'''

def _generate_nan(funcname, f):
    input_args = []
    output_args = []
    args = []
    result_wrap = 'res'
    postprocessing = []
    for i, arg in enumerate(f.arguments):
        # (const unsigned char*) arg1, arg2, (unsigned char*) arg3, arg4
        if isinstance(arg, tuple):
            output_args.append(
                'const size_t res_size = %s;'
                'v8::Local<v8::Object> res = Nan::NewBuffer(res_size).ToLocalChecked();'
                'unsigned char *res_ptr = (unsigned char*) node::Buffer::Data(res);' % arg[1])
            args.append('res_ptr')
            args.append('res_size')
        elif arg.startswith('const_bytes'):
            input_args.append(
                'unsigned char *arg_%s_ptr = (unsigned char*) node::Buffer::Data(info[%s]->ToObject());'
                'size_t arg_%s_size = node::Buffer::Length(info[%s]->ToObject());' % tuple(
                    [i]*4
                )
            )
            args.append('arg_%s_ptr' % i)
            args.append('arg_%s_size' % i)
        elif arg.startswith('uint32_t'):
            args.append('info[%s]->ToInteger()->Value()' % i)
        elif arg.startswith('string'):
            args.append('*Nan::Utf8String(info[%s])' % i)
        elif arg == 'out_str_p':
            output_args.append('char *result_ptr;')
            args.append('&result_ptr')
            result_wrap = 'v8::String::NewFromUtf8(v8::Isolate::GetCurrent(), result_ptr)'
        elif arg == 'out_bytes_sized':
            output_args.extend([
                'const size_t res_size = info[%s]->ToInteger()->Value();' % i,
                'unsigned char *res_ptr = new unsigned char[res_size];',
                'size_t out_size;'
            ])
            args.append('res_ptr')
            args.append('res_size')
            args.append('&out_size')
            postprocessing.append('v8::Local<v8::Object> res = Nan::NewBuffer((char*)res_ptr, out_size).ToLocalChecked();')
        elif arg == 'out_bytes_fixedsized':
            output_args.extend([
                'const size_t res_size = info[%s]->ToInteger()->Value();' % i,
                'v8::Local<v8::Object> res = Nan::NewBuffer(res_size).ToLocalChecked();',
                'unsigned char *res_ptr  = (unsigned char*) node::Buffer::Data(res);'
            ])
            args.append('res_ptr')
            args.append('res_size')
        elif arg == 'bip32_in':
            input_args.append((
                'const ext_key* inkey;'
                'unsigned char* inbuf = (unsigned char*) node::Buffer::Data(info[%s]->ToObject());'
                'bip32_key_unserialize_alloc(inbuf, node::Buffer::Length(info[%s]->ToObject()), &inkey);'
            ) % (i, i))
            args.append('inkey');
            postprocessing.append('bip32_key_free(inkey);')
        elif arg in ['bip32_pub_out', 'bip32_priv_out']:
            output_args.append(
                'const ext_key *outkey;'
                'v8::Local<v8::Object> res = Nan::NewBuffer(BIP32_SERIALIZED_LEN).ToLocalChecked();'
                'unsigned char *out = (unsigned char*) node::Buffer::Data(res);'
            )
            args.append('&outkey')
            flag = {'bip32_pub_out': 'BIP32_FLAG_KEY_PUBLIC',
                    'bip32_priv_out': 'BIP32_FLAG_KEY_PRIVATE'}[arg]
            postprocessing.append('bip32_key_serialize(outkey, %s, out, BIP32_SERIALIZED_LEN);' % flag)
            postprocessing.append('bip32_key_free(outkey);')
    return ('''
        void %s(const Nan::FunctionCallbackInfo<v8::Value>& info) {
            !!input_args!!
            !!output_args!!

            %s(!!args!!);

            !!postprocessing!!

            info.GetReturnValue().Set(%s);
        }
    ''' % (funcname,
           (f.wally_name or funcname) + ('_alloc' if f.nodejs_append_alloc else ''),
           result_wrap)).replace(
        '!!input_args!!', '\n'.join(input_args)
    ).replace(
        '!!output_args!!', '\n'.join(output_args)
    ).replace(
        '!!args!!', ', '.join(args)
    ).replace(
        '!!postprocessing!!', '\n'.join(postprocessing)
    )

def generate(functions):
    nan_implementations = []
    nan_declarations = []
    for i, (funcname, f) in enumerate(functions):
        nan_implementations.append(_generate_nan(funcname, f))
        nan_declarations.append('''
            exports->Set(Nan::New("%s").ToLocalChecked(),
                         Nan::New<v8::FunctionTemplate>(%s)->GetFunction());
        ''' % (funcname, funcname))
    return TEMPLATE.replace(
        '!!nan_impl!!',
        ''.join(nan_implementations)
    ).replace(
        '!!nan_decl!!',
        ''.join(nan_declarations)
    )
