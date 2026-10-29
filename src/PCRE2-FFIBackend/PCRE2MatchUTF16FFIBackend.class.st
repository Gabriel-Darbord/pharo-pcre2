Class {
	#name : 'PCRE2MatchUTF16FFIBackend',
	#superclass : 'PCRE2MatchFFIBackend',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> free [

	self ffiCall: #(void pcre2_match_data_free_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getCount [
	"Return the number of PCRE2 code-unit offset pairs in this 16-bit match data block."

	self ffiCall: #(int pcre2_get_ovector_count_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-16 match-data block, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_heapframes_size_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getMarkPointer [
	"Answer PCRE2's native pointer to the last 16-bit MARK/PRUNE/THEN name, or NULL when no mark is available."

	self ffiCall: #(void *pcre2_get_mark_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getMatchDataSize [
	"Answer the native memory used by this libpcre2-16 match-data block, in bytes."

	self ffiCall: #(size_t pcre2_get_match_data_size_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getOffsets [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_16(self))
]

{ #category : 'private - native' }
PCRE2MatchUTF16FFIBackend >> getStartIndex [

	self ffiCall: #(size_t pcre2_get_startchar_16(self))
]
