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

%define %jsbuffer_mutable_binary(TYPEMAP, SIZE)
%typemap(in) (TYPEMAP, SIZE) {
 $1 = ($1_ltype) node::Buffer::Data($input->ToObject());
 $2 = node::Buffer::Length($input->ToObject());
}
%enddef

%jsbuffer_const_binary(unsigned char *bytes_in, size_t len_in);
%jsbuffer_mutable_binary(unsigned char *bytes_out, size_t len);


%include "../include/wally_core.h"
%include "../include/wally_bip32.h"
%include "bip32_int.h"
%include "../include/wally_bip38.h"
%include "../include/wally_bip39.h"
%include "../include/wally_crypto.h"