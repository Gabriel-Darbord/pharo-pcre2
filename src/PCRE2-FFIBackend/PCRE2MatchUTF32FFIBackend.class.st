"
Owns a match-data handle of the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatchUTF32FFIBackend',
	#superclass : 'PCRE2MatchFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_match_data_free_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getCount [
	"Answer the number of offset pairs in the match data."

	self ffiCall: #(int pcre2_get_ovector_count_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getHeapframesSize [
	"Answer the heap-frame memory retained by the match data, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_heapframes_size_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getMarkPointer [
	"Answer a pointer to the last MARK, PRUNE or THEN name, or NULL when there is none."

	self ffiCall: #(void *pcre2_get_mark_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getMatchDataSize [
	"Answer the memory used by the match data, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_size_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getOffsets [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getStartIndex [

	self ffiCall: #(size_t pcre2_get_startchar_32(self))
]
