"
Locates the native PCRE2 32-bit code-unit library.

This class exists so UTF-32-specific FFI methods can bind to libpcre2-32 while the existing LibPCRE2 class remains the UTF-8/libpcre2-8 binding.
"
Class {
	#name : 'LibPCRE2UTF32',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
LibPCRE2UTF32 class >> libraryBasename [

	^ 'libpcre2-32'
]
