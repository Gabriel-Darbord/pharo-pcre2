"
Owns a match-data handle of the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2MatchUTF8FFIBackend',
	#superclass : 'PCRE2MatchFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> basicFree [

	self ffiCall: #(void pcre2_match_data_free_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getCount [
	"Answer the number of offset pairs in the match data."

	self ffiCall: #(int pcre2_get_ovector_count_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getHeapframesSize [
	"Answer the heap-frame memory retained by the match data, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_heapframes_size_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getMarkPointer [
	"Answer a pointer to the last MARK, PRUNE or THEN name, or NULL when there is none."

	self ffiCall: #(void *pcre2_get_mark_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getMatchDataSize [
	"Answer the memory used by the match data, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_size_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getOffsets [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_8(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF8FFIBackend >> getStartIndex [

	self ffiCall: #(size_t pcre2_get_startchar_8(self))
]
