{
  "targets": [
    {
      "target_name": "deps",
      "sources": [ "../ccan/ccan/crypto/sha512/sha512.c", "../ccan/ccan/crypto/ripemd160/ripemd160.c", "../ccan/ccan/crypto/sha256/sha256.c", "../secp256k1/src/secp256k1.c", "../internal.c" ],
      "defines": [ "SWIG_JAVASCRIPT_BUILD", "HAVE_CONFIG_H" ],
      "include_dirs": [ "../..", "..", "../secp256k1", "../secp256k1/src", "../ccan" ],
      "type": "static_library"
    },
    {
      "target_name": "wallycore",
      "dependencies": [ "deps" ],
      "sources": [ "swig_js_wrap.cxx" ],
      "include_dirs": [ ".." ],
      "libraries": [ "Release/deps.a" ],
      "defines": [ "SWIG_JAVASCRIPT_BUILD", "HAVE_CONFIG_H" ],
    }
  ],
  "conditions": [
    [ 'OS=="mac"', {
      "xcode_settings": {
        "CLANG_CXX_LIBRARY": "libc++"
      }
    }]
  ]
}
