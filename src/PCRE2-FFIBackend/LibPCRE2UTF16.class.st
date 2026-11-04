"
Binding to libpcre2-16, the PCRE2 library for 16-bit code units.
"
Class {
	#name : 'LibPCRE2UTF16',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'code-unit width' }
LibPCRE2UTF16 class >> codeUnitWidth [

	^ 16
]

{ #category : 'code-unit width' }
LibPCRE2UTF16 class >> codeUnitWidthMask [

	^ 2
]

{ #category : 'library path' }
LibPCRE2UTF16 class >> libraryBasename [

	^ 'libpcre2-16'
]

{ #category : 'private' }
LibPCRE2UTF16 >> characterTablesClass [

	^ PCRE2UTF16CharacterTables
]

{ #category : 'private' }
LibPCRE2UTF16 >> config: what output: where [

	self ffiCall: #(int pcre2_config_16(uint32 what, void *where))
]

{ #category : 'private' }
LibPCRE2UTF16 >> convertContextClass [

	^ PCRE2UTF16ConvertContext
]

{ #category : 'private' }
LibPCRE2UTF16 >> convertedPatternFree: convertedPattern [

	self ffiCall: #(void pcre2_converted_pattern_free_16(void *convertedPattern))
]

{ #category : 'private' }
LibPCRE2UTF16 >> createConvertContext [

	self ffiCall: #(void *pcre2_convert_context_create_16(nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> createMatchContext [

	self ffiCall: #(void *pcre2_match_context_create_16(nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> decodeConvertedPatternBytes: convertedBytes codeUnitCount: codeUnitCount [

	^ (PCRE2UTF16Input fromNativeEndianBytes: convertedBytes) readFrom: 1 to: codeUnitCount
]

{ #category : 'private' }
LibPCRE2UTF16 >> deserialize: bytes count: count output: buffer [

	self ffiCall: #(int32 pcre2_serialize_decode_16(void *buffer, int32 count, void *bytes, nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> freeCharacterTables: characterTables [

	self ffiCall: #(void pcre2_maketables_free_16(nil, void *characterTables))
]

{ #category : 'JIT' }
LibPCRE2UTF16 >> jitFreeUnusedMemory [

	self ffiCall: #(void pcre2_jit_free_unused_memory_16(nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> makeCharacterTables [

	self ffiCall: #(void *pcre2_maketables_16(nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> matchContextClass [

	^ PCRE2UTF16MatchContext
]

{ #category : 'private' }
LibPCRE2UTF16 >> patternConvert: pattern upTo: length options: convertOptions output: outputBuffer size: outputLength context: convertContext [
	"The buffers are void* so that UFFI does not convert them as strings."

	self ffiCall: #(int pcre2_pattern_convert_16(void *pattern, size_t length, uint32 convertOptions, void *outputBuffer, SizeTHolder *outputLength, void *convertContext))
]

{ #category : 'private' }
LibPCRE2UTF16 >> preparedConversionInputFor: pattern [

	^ pattern asPCRE2UTF16Input
]

{ #category : 'private' }
LibPCRE2UTF16 >> serialize: matchers count: count output: bytes size: bufferSize [
	"The byte stream written to bytes belongs to PCRE2: free it with serializeFree:."

	self ffiCall: #(int32 pcre2_serialize_encode_16(void *matchers, int32 count, void *bytes, SizeTHolder *bufferSize, nil))
]

{ #category : 'private' }
LibPCRE2UTF16 >> serializeFree: bytes [

	self ffiCall: #(void pcre2_serialize_free_16(void *bytes))
]

{ #category : 'private' }
LibPCRE2UTF16 >> serializedNumberOfCodes: bytes [

	self ffiCall: #(int32 pcre2_serialize_get_number_of_codes_16(void *bytes))
]
