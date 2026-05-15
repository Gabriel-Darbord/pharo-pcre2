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

{ #category : 'private' }
LibPCRE2UTF32 >> deserialize: bytes count: count output: buffer [
	"Decode a UTF-32 serialized byte stream into compiled-pattern pointers."

	self ffiCall:
		#( int32 pcre2_serialize_decode_32 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'private' }
LibPCRE2UTF32 >> serialize: matchers count: count output: bytes size: bufferSize [
	"Encode UTF-32 compiled-pattern pointers into a PCRE2-owned serialized byte stream."

	self ffiCall:
		#( int32 pcre2_serialize_encode_32 #( void #* matchers #, int32
		      count #, void #* bytes #, SizeTHolder #* bufferSize #, nil ) )
]

{ #category : 'private' }
LibPCRE2UTF32 >> serializeFree: bytes [
	"Free a serialized UTF-32 byte stream allocated by PCRE2."

	self ffiCall: #( void pcre2_serialize_free_32 #( void #* bytes ) )
]

{ #category : 'private' }
LibPCRE2UTF32 >> serializedNumberOfCodes: bytes [
	"Return the number of compiled patterns in a serialized UTF-32 byte stream."

	self ffiCall: #( int32 pcre2_serialize_get_number_of_codes_32
		   #( void #* bytes ) )
]
