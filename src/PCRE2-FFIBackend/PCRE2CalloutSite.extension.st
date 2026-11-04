Extension { #name : 'PCRE2CalloutSite' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> fromEnumerationBlock: anExternalAddress [

	^ self new initializeFromEnumerationBlock: anExternalAddress
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> fromEnumerationBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	^ self new initializeFromEnumerationBlock: anExternalAddress codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite >> initializeFromEnumerationBlock: anExternalAddress [

	^ self initializeFromEnumerationBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite >> initializeFromEnumerationBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	| pointerOffset sizeOffset wordSize |
	wordSize := ExternalAddress wordSize.
	sizeOffset := wordSize.

	version := anExternalAddress uint32AtOffset: 0.
	patternPosition := self class sizeTFrom: anExternalAddress atOffset: sizeOffset.
	nextItemLength := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + wordSize.
	number := anExternalAddress uint32AtOffset: sizeOffset + (2 * wordSize).
	stringOffset := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (3 * wordSize).
	stringLength := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (4 * wordSize).
	pointerOffset := sizeOffset + (5 * wordSize).
	string := self class
		          stringFrom: (anExternalAddress pointerAtOffset: pointerOffset)
		          length: stringLength
		          codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> sizeTFrom: anExternalAddress atOffset: structOffsetInBytes [
	"Read a PCRE2_SIZE field from a native PCRE2 struct."

	| wordSize |
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [ ^ anExternalAddress uint64AtOffset: structOffsetInBytes ].
	wordSize == 4 ifTrue: [ ^ anExternalAddress uint32AtOffset: structOffsetInBytes ].
	^ anExternalAddress platformSizeTAt: structOffsetInBytes + 1
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> stringFrom: anExternalAddress length: length [

	^ self stringFrom: anExternalAddress length: length codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> stringFrom: anExternalAddress length: length codeUnitWidth: codeUnitWidth [
	"length is in code units. Answer nil for a null address."

	| bytes byteSize |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [ ^ nil ].
	byteSize := length * (codeUnitWidth // 8).
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index | bytes at: index put: (anExternalAddress uint8AtOffset: index - 1) ].
	^ self stringFromBytes: bytes codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> stringFromBytes: bytes codeUnitWidth: codeUnitWidth [

	codeUnitWidth = 8 ifTrue: [ ^ (PCRE2UTF8Input fromBytes: bytes) readFrom: 1 to: bytes size ].
	codeUnitWidth = 16 ifTrue: [ ^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	codeUnitWidth = 32 ifTrue: [ ^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	PCRE2Error signal: 'Unsupported PCRE2 callout string code-unit width'
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutSite class >> zeroTerminatedStringFrom: anExternalAddress codeUnitWidth: codeUnitWidth [
	"Answer nil for a null address."

	| bytes offset width |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [ ^ nil ].
	width := codeUnitWidth // 8.
	bytes := ByteArray new writeStream.
	offset := 0.
	[
		| allZero |
		allZero := true.
		1 to: width do: [ :index | (anExternalAddress uint8AtOffset: offset + index - 1) = 0 ifFalse: [ allZero := false ] ].
		allZero ] whileFalse: [
			1 to: width do: [ :index | bytes nextPut: (anExternalAddress uint8AtOffset: offset + index - 1) ].
			offset := offset + width ].
	^ self stringFromBytes: bytes contents codeUnitWidth: codeUnitWidth
]
