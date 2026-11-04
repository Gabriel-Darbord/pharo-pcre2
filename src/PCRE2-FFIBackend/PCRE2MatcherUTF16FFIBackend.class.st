"
Owns a compiled-pattern handle of the 16-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatcherUTF16FFIBackend',
	#superclass : 'PCRE2MatcherFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_code_free_16(self))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF16FFIBackend >> codeUnitWidth [

	^ 16
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> createMatchDataFromPattern [

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_16(self, nil))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> createMatchDataWithOvectorSize: ovectorSize [
	"ovectorSize is a number of offset pairs."

	self ffiCall: #(void *pcre2_match_data_create_16(uint32 ovectorSize, nil))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF16FFIBackend >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_dfa_match_16(self, void *subject, size_t end, size_t start, uint32 options, PCRE2MatchUTF16FFIBackend *aMatchData, void *context, void *workspace, size_t workspaceSize))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> enumerateCalloutsWith: callback [

	self ffiCall: #(int pcre2_callout_enumerate_16(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> info: what output: where [

	self ffiCall: #(int pcre2_pattern_info_16(self, uint32 what, void *where))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_jit_match_16(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF16FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_match_16(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF16FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> matchBackendClass [

	^ PCRE2MatchUTF16FFIBackend
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF16FFIBackend >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF16Input
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> privateCopy [
	"The copy has no JIT code and shares the character tables."

	self ffiCall: #(void *pcre2_code_copy_16(self))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> privateCopyWithCharacterTables [
	"The copy has no JIT code."

	self ffiCall: #(void *pcre2_code_copy_with_tables_16(self))
]

{ #category : 'private' }
PCRE2MatcherUTF16FFIBackend >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"The buffers are void* so that UFFI does not convert them as strings."

	self ffiCall: #(int pcre2_substitute_16(self, void *subject, size_t end, size_t start, uint32 substituteOptions, void *aPCRE2Match, void *context, void *replacement, size_t rLength, void *buffer, SizeTHolder outSize))
]
