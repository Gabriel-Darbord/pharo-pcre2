"
Stores match data produced by PCRE2's 16-bit code-unit API.

The result-reading behavior is inherited from PCRE2Match. This subclass only binds the native match-data accessors to the libpcre2-16 entry points.
"
Class {
	#name : 'PCRE2UTF16Match',
	#superclass : 'PCRE2Match',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF16Match >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'external resource management' }
PCRE2UTF16Match >> free [

	self ffiCall: #( void pcre2_match_data_free_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getCount [
	"Return the number of offset pairs in this 16-bit match data block."

	self ffiCall: #( int pcre2_get_ovector_count_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-16 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_heapframes_size_16
		   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getMark [
	"Answer the last MARK/PRUNE/THEN name as a Pharo string, or an empty string when PCRE2 reports no mark."

	| pointer |
	pointer := self getMarkPointer.
	(pointer isNil or: [ pointer isNull ]) ifTrue: [ ^ '' ].
	^ self stringFromZeroTerminatedMark: pointer
]

{ #category : 'private' }
PCRE2UTF16Match >> getMarkPointer [
	"Answer PCRE2's native pointer to the last 16-bit MARK/PRUNE/THEN name, or NULL when no mark is available."

	self ffiCall: #( void #* pcre2_get_mark_16 #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getMatchDataSize [
	"Answer the native memory used by this libpcre2-16 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_size_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getOffsets [

	self ffiCall: #( size_t #* pcre2_get_ovector_pointer_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16Match >> getStartIndex [

	self ffiCall: #( size_t pcre2_get_startchar_16 #( self ) )
]

{ #category : 'accessing' }
PCRE2UTF16Match >> mark [

	^ mark ifNil: [ mark := self getMark ifEmpty: [ nil ] ]
]

{ #category : 'private' }
PCRE2UTF16Match >> stringFromZeroTerminatedMark: anExternalAddress [
	"Decode a zero-terminated native-endian UTF-16 mark name."

	| byteStream bytes offset |
	byteStream := ByteArray new writeStream.
	offset := 0.
	[ (anExternalAddress uint16AtOffset: offset) = 0 ] whileFalse: [
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset).
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset + 1).
		offset := offset + 2 ].
	bytes := byteStream contents.
	^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]
