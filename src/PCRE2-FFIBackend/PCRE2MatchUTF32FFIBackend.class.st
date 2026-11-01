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
	"Return the number of PCRE2 code-unit offset pairs in this 32-bit match data block."

	self ffiCall: #(int pcre2_get_ovector_count_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-32 match-data block, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_heapframes_size_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getMarkPointer [
	"Answer PCRE2's native pointer to the last 32-bit MARK/PRUNE/THEN name, or NULL when no mark is available."

	self ffiCall: #(void *pcre2_get_mark_32(self))
]

{ #category : 'private - FFI' }
PCRE2MatchUTF32FFIBackend >> getMatchDataSize [
	"Answer the native memory used by this libpcre2-32 match-data block, in bytes."

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
