"
Binding to libpcre2-8, the PCRE2 library for 8-bit code units and the default width. It answers the library-wide configuration and version queries.
"
Class {
	#name : 'LibPCRE2UTF8',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
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
LibPCRE2UTF8 >> characterTablesClass [

	^ PCRE2UTF8CharacterTables
]

{ #category : 'private' }
LibPCRE2UTF8 >> config: what output: where [

	self ffiCall: #(int pcre2_config_8(uint32 what, void *where))
]

{ #category : 'private' }
LibPCRE2UTF8 >> convertContextClass [

	^ PCRE2UTF8ConvertContext
]

{ #category : 'private' }
LibPCRE2UTF8 >> convertedPatternFree: convertedPattern [

	self ffiCall: #(void pcre2_converted_pattern_free_8(void *convertedPattern))
]

{ #category : 'private' }
LibPCRE2UTF8 >> createConvertContext [

	self ffiCall: #(void *pcre2_convert_context_create_8(nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> createMatchContext [

	self ffiCall: #(void *pcre2_match_context_create_8(nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [

	^ ZnUTF8Encoder default decodeBytes: convertedBytes
]

{ #category : 'private' }
LibPCRE2UTF8 >> deserialize: bytes count: count output: buffer [

	self ffiCall: #(int32 pcre2_serialize_decode_8(void *buffer, int32 count, void *bytes, nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> freeCharacterTables: characterTables [

	self ffiCall: #(void pcre2_maketables_free_8(nil, void *characterTables))
]

{ #category : 'JIT' }
LibPCRE2UTF8 >> jitFreeUnusedMemory [

	self ffiCall: #(void pcre2_jit_free_unused_memory_8(nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> makeCharacterTables [

	self ffiCall: #(void *pcre2_maketables_8(nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> matchContextClass [

	^ PCRE2UTF8MatchContext
]

{ #category : 'private' }
LibPCRE2UTF8 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [
	"The buffers are void* so that UFFI does not convert them as strings."

	self ffiCall: #(int pcre2_pattern_convert_8(void *pattern, size_t length, uint32 convertOptions, void *outputBuffer, SizeTHolder *outputLength, void *convertContext))
]

{ #category : 'private' }
LibPCRE2UTF8 >> preparedConversionInputFor: pattern [

	^ pattern asPCRE2UTF8Input
]

{ #category : 'private' }
LibPCRE2UTF8 >> serialize: matchers count: count output: bytes size: bufferSize [
	"The byte stream written to bytes belongs to PCRE2: free it with serializeFree:."

	self ffiCall: #(int32 pcre2_serialize_encode_8(void *matchers, int32 count, void *bytes, SizeTHolder *bufferSize, nil))
]

{ #category : 'private' }
LibPCRE2UTF8 >> serializeFree: bytes [

	self ffiCall: #(void pcre2_serialize_free_8(void *bytes))
]

{ #category : 'private' }
LibPCRE2UTF8 >> serializedNumberOfCodes: bytes [

	self ffiCall: #(int32 pcre2_serialize_get_number_of_codes_8(void *bytes))
]
