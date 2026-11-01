"
Owns a compiled-pattern handle of the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatcherUTF32FFIBackend',
	#superclass : 'PCRE2MatcherFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_code_free_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF32FFIBackend >> codeUnitWidth [

	^ 32
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> createMatchDataFromPattern [
	"Create match data sized for this 32-bit compiled pattern."

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_32(self, nil))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> createMatchDataWithOvectorSize: ovectorSize [
	"Create 32-bit match data with room for an explicit number of code-unit offset pairs."

	self ffiCall: #(void *pcre2_match_data_create_32(uint32 ovectorSize, nil))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF32FFIBackend >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [
	"Decode a native-endian UTF-32 substitution output buffer."

	| byteSize bytes |
	codeUnitCount = 0 ifTrue: [ ^ String new ].
	byteSize := codeUnitCount * self codeUnitByteSize.
	bytes := buffer copyFrom: 1 to: byteSize.
	^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"Run pcre2_dfa_match_32 with caller-managed match data and workspace storage. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_dfa_match_32(self, void *subject, size_t end, size_t start, uint32 options, PCRE2MatchUTF32FFIBackend *aMatchData, void *context, void *workspace, size_t workspaceSize))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> enumerateCalloutsWith: callback [
	"Enumerate static callout sites in the compiled 32-bit pattern. This does not run a match or change the matcher.
	int pcre2_callout_enumerate_32(const pcre2_code_32 *code, int (*callback)(pcre2_callout_enumerate_block_32 *, void *), void *user_data)"

	self ffiCall: #(int pcre2_callout_enumerate_32(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> info: what output: where [
	"int pcre2_pattern_info_32(const pcre2_code *code, uint32_t what, void *where)"

	self ffiCall: #(int pcre2_pattern_info_32(self, uint32 what, void *where))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_jit_match_32 on a prepared PCRE2-32 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_jit_match_32(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF32FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"Run pcre2_match_32 on a prepared PCRE2-32 subject buffer. start is a zero-based code-unit offset, end is the subject length in code units, and PCRE2 writes code-unit offsets into the match data."

	self ffiCall: #(int pcre2_match_32(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF32FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> matchBackendClass [

	^ PCRE2MatchUTF32FFIBackend
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF32FFIBackend >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF32Input
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> privateCopy [
	"Copy a compiled 32-bit pattern. The copy does not include JIT data."

	self ffiCall: #(void *pcre2_code_copy_32(self))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> privateCopyWithCharacterTables [
	"Copy a compiled 32-bit pattern and any referenced low-character tables. The copy does not include JIT data.
	pcre2_code *pcre2_code_copy_with_tables_32(const pcre2_code *code)"

	self ffiCall: #(void *pcre2_code_copy_with_tables_32(self))
]

{ #category : 'private' }
PCRE2MatcherUTF32FFIBackend >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"Apply substitutions into caller-provided UTF-32 output storage. Subject, replacement, and output are prepared native-endian code-unit buffers, so use void* to keep UFFI string conversion out of the call.
	int pcre2_substitute_32(const pcre2_code_32 *code, PCRE2_SPTR32 subject, PCRE2_SIZE length, PCRE2_SIZE startoffset, uint32_t options, pcre2_match_data_32 *match_data, pcre2_match_context_32 *mcontext, PCRE2_SPTR32 replacement, PCRE2_SIZE rlength, PCRE2_UCHAR32 *outputbuffer, PCRE2_SIZE *outlengthptr)"

	self ffiCall: #(int pcre2_substitute_32(self, void *subject, size_t end, size_t start, uint32 substituteOptions, void *aPCRE2Match, void *context, void *replacement, size_t rLength, void *buffer, SizeTHolder outSize))
]
