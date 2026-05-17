"
Stores match data produced by PCRE2's 8-bit UTF-8 code-unit API.

The result-reading behavior is inherited from PCRE2Match. This subclass binds the native match-data accessors to the libpcre2-8 entry points used by PCRE2UTF8Matcher.
"
Class {
	#name : 'PCRE2UTF8Match',
	#superclass : 'PCRE2Match',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF8Match >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'external resource management' }
PCRE2UTF8Match >> free [

	self ffiCall: #(void pcre2_match_data_free_8(self))
]

{ #category : 'private' }
PCRE2UTF8Match >> getCount [
	"Return the number of PCRE2 code-unit offset pairs in this 8-bit match data block."

	self ffiCall: #( int pcre2_get_ovector_count_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8Match >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-8 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_heapframes_size_8
		   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8Match >> getMarkPointer [
	"Answer PCRE2's native pointer to the last 8-bit MARK/PRUNE/THEN name, or NULL when no mark is available."

	self ffiCall: #( void #* pcre2_get_mark_8 #( self ) )
]

{ #category : 'private' }
PCRE2UTF8Match >> getMatchDataSize [
	"Answer the native memory used by this libpcre2-8 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_size_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8Match >> getOffsets [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_8(self))
]

{ #category : 'private' }
PCRE2UTF8Match >> getStartIndex [

	self ffiCall: #(size_t pcre2_get_startchar_8(self))
]
