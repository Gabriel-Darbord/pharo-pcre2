"
Owns a compiled-pattern handle of the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatcherUTF8FFIBackend',
	#superclass : 'PCRE2MatcherFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_code_free_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF8FFIBackend >> codeUnitWidth [

	^ 8
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> createMatchDataFromPattern [

	self ffiCall: #(void *pcre2_match_data_create_from_pattern_8(self, nil))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> createMatchDataWithOvectorSize: ovectorSize [
	"ovectorSize is a number of offset pairs."

	self ffiCall: #(void *pcre2_match_data_create_8(uint32 ovectorSize, nil))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> decodeSubstitutionOutput: buffer codeUnits: codeUnitCount [

	codeUnitCount = 0 ifTrue: [ ^ String new ].
	^ (PCRE2UTF8Input bytes: buffer decoder: ZnUTF8Encoder default) readFrom: 1 to: codeUnitCount
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> dfaMatch: subject from: start to: end matchData: aMatchData workspace: workspace size: workspaceSize [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_dfa_match_8(self, void *subject, size_t end, size_t start, uint32 options, PCRE2MatchUTF8FFIBackend *aMatchData, void *context, void *workspace, size_t workspaceSize))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> enumerateCalloutsWith: callback [

	self ffiCall: #(int pcre2_callout_enumerate_8(self, FFICallback callback, nil))
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> info: what output: where [

	self ffiCall: #(int pcre2_pattern_info_8(self, uint32 what, void *where))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> jitMatch: subject from: start to: end options: matchOptions matchData: aMatchData [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_jit_match_8(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF8FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> match: subject from: start to: end options: matchOptions matchData: aMatchData [
	"start is a zero-based code-unit offset and end is the subject length in code units."

	self ffiCall: #(int pcre2_match_8(self, void *subject, size_t end, size_t start, uint32 matchOptions, PCRE2MatchUTF8FFIBackend *aMatchData, void *context))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> matchBackendClass [

	^ PCRE2MatchUTF8FFIBackend
]

{ #category : 'private - FFI' }
PCRE2MatcherUTF8FFIBackend >> preparedInputFor: aStringOrInput [

	^ aStringOrInput asPCRE2UTF8Input
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> privateCopy [
	"The copy has no JIT code and shares the character tables."

	self ffiCall: #(void *pcre2_code_copy_8(self))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> privateCopyWithCharacterTables [
	"The copy has no JIT code."

	self ffiCall: #(void *pcre2_code_copy_with_tables_8(self))
]

{ #category : 'private' }
PCRE2MatcherUTF8FFIBackend >> substitute: subject from: start to: end options: substituteOptions matchData: aPCRE2Match replacement: replacement upTo: rLength output: buffer size: outSize [
	"The buffers are void* so that UFFI does not convert them as strings."

	self ffiCall: #(int pcre2_substitute_8(self, void *subject, size_t end, size_t start, uint32 substituteOptions, void *aPCRE2Match, void *context, void *replacement, size_t rLength, void *buffer, SizeTHolder outSize))
]
