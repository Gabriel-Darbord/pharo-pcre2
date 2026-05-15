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
PCRE2UTF32Match >> getHeapframesSize [
	"Answer the native heap-frame memory retained by this libpcre2-32 match-data block, in bytes."

	self ffiCall: #( size_t pcre2_get_match_data_heapframes_size_32
		   #( self ) )
]

{ #category : 'private' }
PCRE2UTF32Match >> getMark [
	"Answer the last MARK/PRUNE/THEN name as a Pharo string, or an empty string when PCRE2 reports no mark."

	| pointer |
	pointer := self getMarkPointer.
	(pointer isNil or: [ pointer isNull ]) ifTrue: [ ^ '' ].
	^ self stringFromZeroTerminatedMark: pointer
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

{ #category : 'accessing' }
PCRE2UTF32Match >> mark [

	^ mark ifNil: [ mark := self getMark ifEmpty: [ nil ] ]
]

{ #category : 'private' }
PCRE2UTF32Match >> stringFromZeroTerminatedMark: anExternalAddress [
	"Decode a zero-terminated native-endian UTF-32 mark name."

	| byteStream bytes offset |
	byteStream := ByteArray new writeStream.
	offset := 0.
	[ (anExternalAddress uint32AtOffset: offset) = 0 ] whileFalse: [
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset).
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset + 1).
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset + 2).
		byteStream nextPut: (anExternalAddress uint8AtOffset: offset + 3).
		offset := offset + 4 ].
	bytes := byteStream contents.
	^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes
]
