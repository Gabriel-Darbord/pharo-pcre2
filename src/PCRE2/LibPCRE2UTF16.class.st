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

{ #category : 'private' }
LibPCRE2UTF16 >> deserialize: bytes count: count output: buffer [
	"Decode a UTF-16 serialized byte stream into compiled-pattern pointers."

	self ffiCall:
		#( int32 pcre2_serialize_decode_16 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'private' }
LibPCRE2UTF16 >> serialize: matchers count: count output: bytes size: bufferSize [
	"Encode UTF-16 compiled-pattern pointers into a PCRE2-owned serialized byte stream."

	self ffiCall:
		#( int32 pcre2_serialize_encode_16 #( void #* matchers #, int32
		      count #, void #* bytes #, SizeTHolder #* bufferSize #, nil ) )
]

{ #category : 'private' }
LibPCRE2UTF16 >> serializeFree: bytes [
	"Free a serialized UTF-16 byte stream allocated by PCRE2."

	self ffiCall: #( void pcre2_serialize_free_16 #( void #* bytes ) )
]

{ #category : 'private' }
LibPCRE2UTF16 >> serializedNumberOfCodes: bytes [
	"Return the number of compiled patterns in a serialized UTF-16 byte stream."

	self ffiCall: #( int32 pcre2_serialize_get_number_of_codes_16
		   #( void #* bytes ) )
]
