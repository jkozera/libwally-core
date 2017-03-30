{
  "targets": [
    {
      "target_name": "deps",
      "sources": [ "<(libwally_dir)/src/ccan/ccan/crypto/sha512/sha512.c", "<(libwally_dir)/src/ccan/ccan/crypto/ripemd160/ripemd160.c", "<(libwally_dir)/src/ccan/ccan/crypto/sha256/sha256.c", "<(libwally_dir)/src/secp256k1/src/secp256k1.c", "<(libwally_dir)/src/internal.c", "<(libwally_dir)/src/base58.c", "<(libwally_dir)/src/aes.c", "<(libwally_dir)/src/scrypt.c", "<(libwally_dir)/src/pbkdf2.c", "<(libwally_dir)/src/hmac.c", "<(libwally_dir)/src/bip38.c", "<(libwally_dir)/src/sign.c" ],
      "defines": [ "SWIG_JAVASCRIPT_BUILD", "HAVE_CONFIG_H" ],
      "include_dirs": [ "<(libwally_dir)", "<(libwally_dir)/src", "<(libwally_dir)/src/secp256k1", "<(libwally_dir)/src/secp256k1/src", "<(libwally_dir)/src/ccan" ],
      "type": "static_library"
    },
    {
      "target_name": "wallycore",
      "dependencies": [ "deps" ],
      "sources": [ "nan_wrap.cc" ],
      "include_dirs": [ "<(libwally_dir)/src", "<!(node -e \"require('nan')\")" ],
      "libraries": [ "Release/deps.a" ],
      "defines": [ "SWIG_JAVASCRIPT_BUILD", "HAVE_CONFIG_H" ],
    }
  ],
  "conditions": [
    [ 'OS=="mac"', {
      "xcode_settings": {
        "CLANG_CXX_LIBRARY": "libc++"
      }
    }],
    [ 'OS=="win"', {
      "variables": {
        "libwally_dir": "<!(echo %LIBWALLY_DIR%)"
      }
    }],
    [ 'OS!="win"', {
      "variables": {
        "libwally_dir": "<!(echo $LIBWALLY_DIR)"
      }
    }]
  ]
}
