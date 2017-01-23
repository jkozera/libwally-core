%module wallycore
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
%}

%define %jsbuffer_const_binary(TYPEMAP, SIZE)
%typemap(in) (const TYPEMAP, SIZE) {
 $1 = ($1_ltype) node::Buffer::Data($input->ToObject());
 $2 = node::Buffer::Length($input->ToObject());
}
%enddef

%define %jsbuffer_out_binary(TYPEMAP, SIZE, LEN)
%typemap(in,numinputs=0) (TYPEMAP, SIZE) {
  $2 = 32;
  $1 = new $*1_ltype[$2];
}
%typemap(argout) (TYPEMAP, SIZE) {
  v8::Local<v8::Object> buf = node::Buffer::New(v8::Isolate::GetCurrent(), $2).ToLocalChecked();
  memcpy(node::Buffer::Data(buf), $1, $2);
  delete[] $1;
  $result = buf;
}
%enddef

%jsbuffer_const_binary(unsigned char *bytes_in, size_t len_in);
// TODO hardcode 32 only for the really 32-long arrays
%jsbuffer_out_binary(unsigned char *bytes_out, size_t len, 32);


%include "../include/wally_core.h"
%include "../include/wally_bip32.h"
%include "bip32_int.h"
%include "../include/wally_bip38.h"
%include "../include/wally_bip39.h"
%include "../include/wally_crypto.h"
