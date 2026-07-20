"
I represent a callout site discovered in a compiled PCRE2 pattern.

PCRE2 can enumerate callout points without running a match. That is useful for tools such as regex explainers/debuggers because it reveals where numbered, string, or automatic callouts appear in the compiled pattern while leaving normal matching behavior untouched.

My offsets are raw PCRE2 pattern code-unit offsets for the matcher width used to compile the pattern. `matchesEvent:` links me back to a runtime `PCRE2CalloutEvent` when a trace wants static pattern metadata for an event.
"
Class {
	#name : 'PCRE2CalloutSite',
	#superclass : 'Object',
	#instVars : [
		'version',
		'patternPosition',
		'nextItemLength',
		'number',
		'stringOffset',
		'stringLength',
		'string'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2CalloutSite class >> fromEnumerationBlock: anExternalAddress [

	^ self new initializeFromEnumerationBlock: anExternalAddress
]

{ #category : 'instance creation' }
PCRE2CalloutSite class >> fromEnumerationBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	^ self new
		  initializeFromEnumerationBlock: anExternalAddress
		  codeUnitWidth: codeUnitWidth
]

{ #category : 'private' }
PCRE2CalloutSite class >> sizeTFrom: anExternalAddress atOffset: structOffsetInBytes [
	"Read a PCRE2_SIZE field from a native PCRE2 struct. This ExternalAddress offset is measured in bytes, not in subject or pattern code units."

	| wordSize |
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [
		^ anExternalAddress uint64AtOffset: structOffsetInBytes ].
	wordSize == 4 ifTrue: [
		^ anExternalAddress uint32AtOffset: structOffsetInBytes ].
	^ anExternalAddress platformSizeTAt: structOffsetInBytes + 1
]

{ #category : 'private' }
PCRE2CalloutSite class >> stringFrom: anExternalAddress length: length [

	^ self stringFrom: anExternalAddress length: length codeUnitWidth: 8
]

{ #category : 'private' }
PCRE2CalloutSite class >> stringFrom: anExternalAddress length: length codeUnitWidth: codeUnitWidth [
	"Decode a string callout payload for the given PCRE2 code-unit width."

	| bytes byteSize |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [
		^ nil ].
	byteSize := length * (codeUnitWidth // 8).
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index |
		bytes at: index put: (anExternalAddress uint8AtOffset: index - 1) ].
	^ self stringFromBytes: bytes codeUnitWidth: codeUnitWidth
]

{ #category : 'private' }
PCRE2CalloutSite class >> stringFromBytes: bytes codeUnitWidth: codeUnitWidth [
	"Decode native PCRE2 string bytes for the given code-unit width."

	codeUnitWidth = 8 ifTrue: [ ^ bytes utf8Decoded ].
	codeUnitWidth = 16 ifTrue: [
		^ (PCRE2UTF16Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	codeUnitWidth = 32 ifTrue: [
		^ (PCRE2UTF32Input fromNativeEndianBytes: bytes) decodeBytes: bytes ].
	PCRE2Error signal: 'Unsupported PCRE2 callout string code-unit width'
]

{ #category : 'private' }
PCRE2CalloutSite class >> zeroTerminatedStringFrom: anExternalAddress codeUnitWidth: codeUnitWidth [
	"Decode a zero-terminated native PCRE2 string for the given code-unit width."

	| bytes offset width |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [
		^ nil ].
	width := codeUnitWidth // 8.
	bytes := ByteArray new writeStream.
	offset := 0.
	[
	| allZero |
	allZero := true.
	1 to: width do: [ :index |
		(anExternalAddress uint8AtOffset: offset + index - 1) = 0 ifFalse: [
			allZero := false ] ].
	allZero ] whileFalse: [
		1 to: width do: [ :index |
			bytes nextPut:
				(anExternalAddress uint8AtOffset: offset + index - 1) ].
		offset := offset + width ].
	^ self stringFromBytes: bytes contents codeUnitWidth: codeUnitWidth
]

{ #category : 'testing' }
PCRE2CalloutSite >> hasString [

	^ string notNil
]

{ #category : 'initialization' }
PCRE2CalloutSite >> initializeFromEnumerationBlock: anExternalAddress [

	^ self
		  initializeFromEnumerationBlock: anExternalAddress
		  codeUnitWidth: 8
]

{ #category : 'initialization' }
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

{ #category : 'testing' }
PCRE2CalloutSite >> isAutomatic [
	"Answer whether this site was generated by PCRE2_AUTO_CALLOUT rather than an explicit (?C...) item."

	^ number = PCRE2 automaticCalloutNumber and: [ string isNil ]
]

{ #category : 'testing' }
PCRE2CalloutSite >> matchesEvent: aPCRE2CalloutEvent [
	"Answer whether this static site corresponds to the runtime callout event."

	^ patternPosition = aPCRE2CalloutEvent patternPosition and: [
		  number = aPCRE2CalloutEvent number and: [
			  string = aPCRE2CalloutEvent string ] ]
]

{ #category : 'accessing' }
PCRE2CalloutSite >> nextItemLength [
	"Answer the length of the next pattern item in PCRE2 code units."

	^ nextItemLength
]

{ #category : 'accessing' }
PCRE2CalloutSite >> number [

	^ number
]

{ #category : 'accessing' }
PCRE2CalloutSite >> patternPosition [
	"Answer the pattern position for this static callout site as a zero-based PCRE2 code-unit offset."

	^ patternPosition
]

{ #category : 'printing' }
PCRE2CalloutSite >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: patternPosition;
		nextPutAll: ', ';
		print: number.
	string ifNotNil: [
		aStream
			nextPutAll: ', ';
			print: string ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
PCRE2CalloutSite >> string [

	^ string
]

{ #category : 'accessing' }
PCRE2CalloutSite >> stringLength [
	"Answer the callout string length in PCRE2 code units."

	^ stringLength
]

{ #category : 'accessing' }
PCRE2CalloutSite >> stringOffset [
	"Answer the callout string's pattern position as a zero-based PCRE2 code-unit offset."

	^ stringOffset
]

{ #category : 'accessing' }
PCRE2CalloutSite >> version [

	^ version
]
