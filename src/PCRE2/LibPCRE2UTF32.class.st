"
Concrete binding for the native PCRE2 32-bit code-unit library.

This class locates libpcre2-32 and owns library-level FFI primitives that call *_32 symbols, such as configuration, serialization, match-context creation, and JIT memory cleanup. UTF-32 compiler, matcher, match, context, JIT, and serialization code use this library class.
"
Class {
	#name : 'LibPCRE2UTF32',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'code-unit width' }
LibPCRE2UTF32 class >> codeUnitWidth [

	^ 32
]

{ #category : 'code-unit width' }
LibPCRE2UTF32 class >> codeUnitWidthMask [

	^ 4
]

{ #category : 'library path' }
LibPCRE2UTF32 class >> libraryBasename [

	^ 'libpcre2-32'
]

{ #category : 'private' }
LibPCRE2UTF32 >> config: what output: where [
	"Return configuration information from libpcre2-32."

	self ffiCall:
		#( int pcre2_config_32 #( uint32 what #, void #* where ) )
]

{ #category : 'private' }
LibPCRE2UTF32 >> createMatchContext [
	"Create and initialize a new UTF-32 match context."

	self ffiCall:
		#( #PCRE2UTF32MatchContext #* pcre2_match_context_create_32
		   #( nil ) )
]

{ #category : 'private' }
LibPCRE2UTF32 >> deserialize: bytes count: count output: buffer [
	"Decode a UTF-32 serialized byte stream into compiled-pattern pointers."

	self ffiCall:
		#( int32 pcre2_serialize_decode_32 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'JIT' }
LibPCRE2UTF32 >> jitFreeUnusedMemory [
	"Release unused executable memory retained by PCRE2's JIT allocator for libpcre2-32."

	self ffiCall: #( void pcre2_jit_free_unused_memory_32
		   #( nil ) )
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
