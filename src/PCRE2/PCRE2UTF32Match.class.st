"
Stores match data produced by PCRE2's 32-bit code-unit API.

The result-reading behavior is inherited from PCRE2Match. This subclass only binds the native match-data accessors to the libpcre2-32 entry points.
"
Class {
	#name : 'PCRE2UTF32Match',
	#superclass : 'PCRE2Match',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF32Match >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'external resource management' }
PCRE2UTF32Match >> free [

	self ffiCall: #( void pcre2_match_data_free_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getCount [
	"Return the number of PCRE2 code-unit offset pairs in this 32-bit match data block."

	self ffiCall: #( int pcre2_get_ovector_count_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-32 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_heapframes_size_32
		   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getMarkPointer [
	"Answer PCRE2's native pointer to the last 32-bit MARK/PRUNE/THEN name, or NULL when no mark is available."

	self ffiCall: #( void #* pcre2_get_mark_32 #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getMatchDataSize [
	"Answer the native memory used by this libpcre2-32 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_size_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getOffsets [

	self ffiCall: #( size_t #* pcre2_get_ovector_pointer_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getStartIndex [

	self ffiCall: #( size_t pcre2_get_startchar_32 #( self ) )
]
