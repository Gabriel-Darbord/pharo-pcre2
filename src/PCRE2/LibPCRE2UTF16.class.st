"
Locates the native PCRE2 16-bit code-unit library.

This class exists so UTF-16-specific FFI methods can bind to libpcre2-16 while the existing LibPCRE2 class remains the UTF-8/libpcre2-8 binding.
"
Class {
	#name : 'LibPCRE2UTF16',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
LibPCRE2UTF16 class >> libraryBasename [

	^ 'libpcre2-16'
]
