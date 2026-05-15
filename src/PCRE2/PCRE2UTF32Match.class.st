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
	"Return the number of offset pairs in this 32-bit match data block."

	self ffiCall: #( int pcre2_get_ovector_count_32
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getMark [
	"PCRE2-32 returns a pointer to a 32-bit code-unit mark name. Mark decoding is not implemented for UTF-32 yet."

	^ nil
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

{ #category : 'accessing' }
PCRE2UTF32Match >> mark [
	"UTF-32 mark-name decoding is not implemented yet."

	^ nil
]
