TEMPLATE = '''%module wallycore
%{
extern "C" {
#define SWIG_FILE_WITH_INIT
#include "../include/wally_core.h"
#include "../include/wally_bip32.h"
#include "bip32_int.h"
#include "../include/wally_bip38.h"
#include "../include/wally_bip39.h"
#include "../include/wally_crypto.h"
}

#include <node_buffer.h>

/* Uint32 handling */
static uint32_t uint32_cast(v8::Local<v8::Value> value) {
    //if (value < 0 || value > UINT_MAX)
        // TODO JS exception SWIG_JavaThrowException(jenv, SWIG_JavaIndexOutOfBoundsException, "Invalid uint32_t");
    return value->ToUint32()->Value();
}

%}

/* Uint32 handling */
/* uint32_t input arguments are taken as longs and cast with range checking */
%typemap(in) uint32_t {
    $1 = uint32_cast($input);
}

/* Array handling */
%typemap(in) (const char *STRING, size_t LENGTH) {
  $1 = ($1_ltype) node::Buffer::Data($input->ToObject());
  $2 = node::Buffer::Length($input->ToObject());
}
%typemap(in) (char *STRING, size_t LENGTH) (
  char *buf = nullptr,
  int alloc = 0
) {
}
%typemap(argout) (char *STRING, size_t LENGTH) (
  v8::Local<v8::Object> jsbuf,
  int alloc = 0
) {
  $result = jsbuf;
}
%apply(const char *STRING, size_t LENGTH) { (const unsigned char *bytes_in, size_t len_in) };
%apply(char *STRING, size_t LENGTH) { (unsigned char *bytes_out, size_t len) };

/* Output strings are converted to native JS strings and returned */
%typemap(in, numinputs=0) char** (char* txt) {
   txt = NULL;
   $1 = ($1_ltype)&txt;
}
%typemap(argout) char** {
   if (*$1 != NULL) {
       $result = v8::String::NewFromUtf8(v8::Isolate::GetCurrent(), *$1);
       wally_free_string(*$1);
   }
}

%define %returns_array_(FUNC, ARRAYARG, LENARG, LEN)
%exception FUNC {
  arg ## LENARG = LEN;
  arg ## ARRAYARG = new std::remove_pointer<typeof(arg ## ARRAYARG)>::type[LEN];

  $action

  if (result == WALLY_OK) {
    jsbuf ## ARRAYARG = node::Buffer::New(v8::Isolate::GetCurrent(), arg ## LENARG).ToLocalChecked();
    memcpy(node::Buffer::Data(jsbuf ## ARRAYARG), arg ## ARRAYARG, arg ## LENARG);
    jsresult = jsbuf ## ARRAYARG;
  } // TODO error handling

  wally_bzero(arg ## ARRAYARG, LEN);
  delete[] arg ## ARRAYARG;
}
%enddef

!!list_of_returns_array!!

%include "../include/wally_core.h"
%include "../include/wally_bip32.h"
%include "bip32_int.h"
%include "../include/wally_bip38.h"
%include "../include/wally_bip39.h"
%include "../include/wally_crypto.h"
'''


def generate(functions):
    list_of_returns_array = []
    for funcname, f in functions:
        argnum = 1
        for arg in f.arguments:
            if isinstance(arg, tuple):
                if arg[0] == 'out_bytes':
                    list_of_returns_array.append(
                        '%%returns_array_(%s, %s, %s, %s)' % (
                            funcname, argnum, argnum + 1, arg[1]
                        )
                    )
            elif '_bytes' in arg:
                argnum += 2
            else:
                argnum += 1
    return TEMPLATE.replace(
        '!!list_of_returns_array!!',
        '\n'.join(list_of_returns_array)
    )
