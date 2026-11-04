"
Binding to libpcre2-32, the PCRE2 library for 32-bit code units.
"
Class {
	#name : 'LibPCRE2UTF32',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
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
LibPCRE2UTF32 >> characterTablesClass [

	^ PCRE2UTF32CharacterTables
]

{ #category : 'private' }
LibPCRE2UTF32 >> config: what output: where [

	self ffiCall: #(int pcre2_config_32(uint32 what, void *where))
]

{ #category : 'private' }
LibPCRE2UTF32 >> convertContextClass [

	^ PCRE2UTF32ConvertContext
]

{ #category : 'private' }
LibPCRE2UTF32 >> convertedPatternFree: convertedPattern [

	self ffiCall: #(void pcre2_converted_pattern_free_32(void *convertedPattern))
]

{ #category : 'private' }
LibPCRE2UTF32 >> createConvertContext [

	self ffiCall: #(void *pcre2_convert_context_create_32(nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> createMatchContext [

	self ffiCall: #(void *pcre2_match_context_create_32(nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [

	^ (PCRE2UTF32Input fromNativeEndianBytes: convertedBytes) readFrom: 1 to: codeUnitCount
]

{ #category : 'private' }
LibPCRE2UTF32 >> deserialize: bytes count: count output: buffer [

	self ffiCall: #(int32 pcre2_serialize_decode_32(void *buffer, int32 count, void *bytes, nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> freeCharacterTables: characterTables [

	self ffiCall: #(void pcre2_maketables_free_32(nil, void *characterTables))
]

{ #category : 'JIT' }
LibPCRE2UTF32 >> jitFreeUnusedMemory [

	self ffiCall: #(void pcre2_jit_free_unused_memory_32(nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> makeCharacterTables [

	self ffiCall: #(void *pcre2_maketables_32(nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> matchContextClass [

	^ PCRE2UTF32MatchContext
]

{ #category : 'private' }
LibPCRE2UTF32 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [
	"The buffers are void* so that UFFI does not convert them as strings."

	self ffiCall: #(int pcre2_pattern_convert_32(void *pattern, size_t length, uint32 convertOptions, void *outputBuffer, SizeTHolder *outputLength, void *convertContext))
]

{ #category : 'private' }
LibPCRE2UTF32 >> preparedConversionInputFor: pattern [

	^ pattern asPCRE2UTF32Input
]

{ #category : 'private' }
LibPCRE2UTF32 >> serialize: matchers count: count output: bytes size: bufferSize [
	"The byte stream written to bytes belongs to PCRE2: free it with serializeFree:."

	self ffiCall: #(int32 pcre2_serialize_encode_32(void *matchers, int32 count, void *bytes, SizeTHolder *bufferSize, nil))
]

{ #category : 'private' }
LibPCRE2UTF32 >> serializeFree: bytes [

	self ffiCall: #(void pcre2_serialize_free_32(void *bytes))
]

{ #category : 'private' }
LibPCRE2UTF32 >> serializedNumberOfCodes: bytes [

	self ffiCall: #(int32 pcre2_serialize_get_number_of_codes_32(void *bytes))
]
