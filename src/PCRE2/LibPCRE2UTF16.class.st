"
Concrete binding for the native PCRE2 16-bit code-unit library.

This class locates libpcre2-16 and owns library-level FFI primitives that call *_16 symbols, such as configuration, serialization, match-context creation, and JIT memory cleanup. UTF-16 compiler, matcher, match, context, JIT, and serialization code use this library class.
"
Class {
	#name : 'LibPCRE2UTF16',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'code-unit width' }
LibPCRE2UTF16 class >> codeUnitWidth [

	^ 16
]

{ #category : 'code-unit width' }
LibPCRE2UTF16 class >> codeUnitWidthMask [

	^ 2
]

{ #category : 'accessing' }
LibPCRE2UTF16 class >> libraryBasename [

	^ 'libpcre2-16'
]

{ #category : 'private' }
LibPCRE2UTF16 >> config: what output: where [
	"Return configuration information from libpcre2-16."

	self ffiCall:
		#( int pcre2_config_16 #( uint32 what #, void #* where ) )
]

{ #category : 'private' }
LibPCRE2UTF16 >> createMatchContext [
	"Create and initialize a new UTF-16 match context."

	self ffiCall:
		#( #PCRE2UTF16MatchContext #* pcre2_match_context_create_16
		   #( nil ) )
]

{ #category : 'private' }
LibPCRE2UTF16 >> deserialize: bytes count: count output: buffer [
	"Decode a UTF-16 serialized byte stream into compiled-pattern pointers."

	self ffiCall:
		#( int32 pcre2_serialize_decode_16 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'JIT' }
LibPCRE2UTF16 >> jitFreeUnusedMemory [
	"Release unused executable memory retained by PCRE2's JIT allocator for libpcre2-16."

	self ffiCall: #( void pcre2_jit_free_unused_memory_16
		   #( nil ) )
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
