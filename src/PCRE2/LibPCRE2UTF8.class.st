"
Concrete binding for the native PCRE2 8-bit code-unit library.

This class locates libpcre2-8 and owns library-level FFI primitives that call *_8 symbols, such as configuration, serialization, conversion, match-context creation, and JIT memory cleanup. UTF-8 compiler, matcher, match, context, JIT, conversion, and default PCRE2 objects use this library class.
"
Class {
	#name : 'LibPCRE2UTF8',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'code-unit width' }
LibPCRE2UTF8 class >> codeUnitWidth [

	^ 8
]

{ #category : 'code-unit width' }
LibPCRE2UTF8 class >> codeUnitWidthMask [

	^ 1
]

{ #category : 'library path' }
LibPCRE2UTF8 class >> libraryBasename [

	^ 'libpcre2-8'
]

{ #category : 'private' }
LibPCRE2UTF8 >> config: what output: where [
	"This function makes it possible for a client program to find out which optional features are available in the version of the PCRE2 library it is using.
	int pcre2_config(uint32_t what, void *where)"

	self ffiCall:
		#( int pcre2_config_8 #( uint32 what #, void #* where ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> convertedPatternFree: convertedPattern [
	"Free a converted pattern allocated by PCRE2."

	self ffiCall:
		#( void pcre2_converted_pattern_free_8
		   #( void #* convertedPattern ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> createConvertContext [
	"Create a native UTF-8 conversion context.
	pcre2_convert_context *pcre2_convert_context_create_8(pcre2_general_context *gcontext)"

	self ffiCall:
		#( #PCRE2UTF8ConvertContext #* pcre2_convert_context_create_8
		   #( nil ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> createMatchContext [
	"Create and initialize a new UTF-8 match context."

	self ffiCall:
		#( #PCRE2UTF8MatchContext #* pcre2_match_context_create_8
		   #( nil ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [

	^ ZnUTF8Encoder default decodeBytes: convertedBytes
]

{ #category : 'private' }
LibPCRE2UTF8 >> deserialize: bytes count: count output: buffer [
	"Decode a serialized byte stream into compiled-pattern pointers. Both arguments are raw byte/pointer buffers prepared by the caller, so keep UFFI out of their contents with void*.
	int32_t pcre2_serialize_decode_8(pcre2_code **codes, int32_t number_of_codes, const uint8_t *bytes, pcre2_general_context *gcontext)"

	self ffiCall:
		#( int32 pcre2_serialize_decode_8 #( void #* buffer #, int32 count
		      #, void #* bytes #, nil ) )
]

{ #category : 'JIT' }
LibPCRE2UTF8 >> jitFreeUnusedMemory [
	"Release unused executable memory retained by PCRE2's JIT allocator for libpcre2-8."

	self ffiCall: #( void pcre2_jit_free_unused_memory_8
	   #( nil ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [
	"Convert a foreign UTF-8 pattern buffer. The input and output pointer slot are raw buffers, so keep UFFI string conversion out with void*.
	int pcre2_pattern_convert_8(PCRE2_SPTR pattern, PCRE2_SIZE length, uint32_t options, PCRE2_UCHAR **buffer, PCRE2_SIZE *blength, pcre2_convert_context *cvcontext)"

	self ffiCall:
		#( int pcre2_pattern_convert_8 #( void #* pattern #, size_t length
		      #, uint32 convertOptions #, void #* outputBuffer #, SizeTHolder
		      #* outputLength #, void #* convertContext ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> preparedConversionInputFor: pattern [

	^ pattern asPCRE2UTF8Input
]

{ #category : 'private' }
LibPCRE2UTF8 >> serialize: matchers count: count output: bytes size: bufferSize [
	"Encode compiled-pattern pointers into a PCRE2-owned serialized byte stream. The pointers table and output pointer slot are raw memory buffers, so pass them as void*.
	int32_t pcre2_serialize_encode_8(const pcre2_code **codes, int32_t number_of_codes, uint8_t **serialized_bytes, PCRE2_SIZE *serialized_size, pcre2_general_context *gcontext)"

	self ffiCall:
		#( int32 pcre2_serialize_encode_8 #( void #* matchers #, int32 count
		      #, void #* bytes #, SizeTHolder #* bufferSize #, nil ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> serializeFree: bytes [
	"Free a serialized byte stream allocated by PCRE2."

	self ffiCall: #( void pcre2_serialize_free_8 #( void #* bytes ) )
]

{ #category : 'private' }
LibPCRE2UTF8 >> serializedNumberOfCodes: bytes [
	"Return the number of compiled patterns in a serialized byte stream. The byte stream is already materialized, so pass it as an opaque buffer.
	int32_t pcre2_serialize_get_number_of_codes_8(const uint8_t *bytes)"

	self ffiCall: #( int32 pcre2_serialize_get_number_of_codes_8
		   #( void #* bytes ) )
]
