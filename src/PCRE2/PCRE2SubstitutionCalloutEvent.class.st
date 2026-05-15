"
I am a snapshot of a PCRE2 substitution callout.

PCRE2 creates me after a replacement has been processed by `pcre2_substitute_8`, before the replacement is finally accepted. I copy the native offsets and the affected input/output text while the callback is running, so clients can safely keep events afterwards.

Offsets are PCRE2 byte/code-unit offsets. The full-match offsets come from the current match ovector in the original subject. The output offsets identify the processed replacement in the output buffer.
"
Class {
	#name : 'PCRE2SubstitutionCalloutEvent',
	#superclass : 'Object',
	#instVars : [
		'version',
		'substitutionCount',
		'offsets',
		'outputOffsets',
		'ovectorCount',
		'matchedText',
		'replacementText'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'private' }
PCRE2SubstitutionCalloutEvent class >> alignedOffsetAfterUInt32ForWordSize: wordSize [
	"Answer the offset of the first pointer field after a uint32_t in the native struct."

	^ 4 + wordSize - 1 // wordSize * wordSize
]

{ #category : 'instance creation' }
PCRE2SubstitutionCalloutEvent class >> fromCalloutBlock: anExternalAddress [

	^ self fromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : 'instance creation' }
PCRE2SubstitutionCalloutEvent class >> fromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	^ self new
		  initializeFromCalloutBlock: anExternalAddress
		  codeUnitWidth: codeUnitWidth
]

{ #category : 'private' }
PCRE2SubstitutionCalloutEvent class >> offsetsFrom: anExternalAddress count: count [

	^ PCRE2CalloutEvent offsetsFrom: anExternalAddress count: count
]

{ #category : 'private' }
PCRE2SubstitutionCalloutEvent class >> sizeTFrom: anExternalAddress atOffset: byteOffset [

	^ PCRE2CalloutEvent sizeTFrom: anExternalAddress atOffset: byteOffset
]

{ #category : 'private' }
PCRE2SubstitutionCalloutEvent class >> stringFrom: anExternalAddress startOffset: startOffset endOffset: endOffset [

	^ self
		  stringFrom: anExternalAddress
		  startOffset: startOffset
		  endOffset: endOffset
		  codeUnitWidth: 8
]

{ #category : 'private' }
PCRE2SubstitutionCalloutEvent class >> stringFrom: anExternalAddress startOffset: startOffset endOffset: endOffset codeUnitWidth: codeUnitWidth [
	"Decode a substring addressed by PCRE2_SIZE code-unit offsets."

	| bytes byteStart byteSize length unitSize |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [
		^ nil ].
	(startOffset = PCRE2 unsetOffset or: [ endOffset = PCRE2 unsetOffset ])
		ifTrue: [ ^ nil ].
	length := endOffset - startOffset.
	length <= 0 ifTrue: [ ^ '' ].
	unitSize := codeUnitWidth // 8.
	byteStart := startOffset * unitSize.
	byteSize := length * unitSize.
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index |
		bytes
			at: index
			put: (anExternalAddress uint8AtOffset: byteStart + index - 1) ].
	^ PCRE2CalloutSite
		  stringFromBytes: bytes
		  codeUnitWidth: codeUnitWidth
]

{ #category : 'initialization' }
PCRE2SubstitutionCalloutEvent >> initializeFromCalloutBlock: anExternalAddress [

	^ self initializeFromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : 'initialization' }
PCRE2SubstitutionCalloutEvent >> initializeFromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	| inputPointer outputPointer ovectorPointer outputOffsetsOffset ovectorPointerOffset pointerOffset wordSize |
	wordSize := ExternalAddress wordSize.
	pointerOffset := self class alignedOffsetAfterUInt32ForWordSize:
		                 wordSize.
	outputOffsetsOffset := pointerOffset + (2 * wordSize).
	ovectorPointerOffset := outputOffsetsOffset + (2 * wordSize).

	version := anExternalAddress uint32AtOffset: 0.
	inputPointer := anExternalAddress pointerAtOffset: pointerOffset.
	outputPointer := anExternalAddress pointerAtOffset:
		                 pointerOffset + wordSize.
	outputOffsets := {
		                 (self class
			                  sizeTFrom: anExternalAddress
			                  atOffset: outputOffsetsOffset).
		                 (self class
			                  sizeTFrom: anExternalAddress
			                  atOffset: outputOffsetsOffset + wordSize) }.
	ovectorPointer := anExternalAddress pointerAtOffset:
		                  ovectorPointerOffset.
	ovectorCount := anExternalAddress uint32AtOffset:
		                ovectorPointerOffset + wordSize.
	substitutionCount := anExternalAddress uint32AtOffset:
		                     ovectorPointerOffset + wordSize + 4.
	offsets := self class
		           offsetsFrom: ovectorPointer
		           count: ovectorCount * 2.
	matchedText := offsets isEmpty
		               ifTrue: [ nil ]
		               ifFalse: [
			               self class
				               stringFrom: inputPointer
				               startOffset: offsets first
				               endOffset: offsets second
				               codeUnitWidth: codeUnitWidth ].
	replacementText := self class
		                   stringFrom: outputPointer
		                   startOffset: outputOffsets first
		                   endOffset: outputOffsets second
		                   codeUnitWidth: codeUnitWidth.
	^ self
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> matchedText [
	"Answer the subject substring matched for this substitution."

	^ matchedText
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> offsets [
	"Answer raw zero-based ovector offsets for the current match."

	^ offsets
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> offsetsAt: pairIndex [
	"Answer the requested zero-based {start. exclusiveEnd} ovector pair."

	| index |
	index := 2 * (pairIndex - 1).
	^ {
		  (offsets at: index + 1).
		  (offsets at: index + 2) }
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> outputOffsets [
	"Answer raw zero-based offsets of the processed replacement in the output buffer."

	^ outputOffsets
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> ovectorCount [
	"Answer the number of ovector pairs available in this event."

	^ ovectorCount
]

{ #category : 'printing' }
PCRE2SubstitutionCalloutEvent >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: substitutionCount;
		nextPutAll: ', ';
		print: matchedText;
		nextPutAll: ' -> ';
		print: replacementText;
		nextPut: $)
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> replacementText [
	"Answer the processed replacement text before the callout accepts or rejects it."

	^ replacementText
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> substitutionCount [
	"Answer the one-based substitution number reported by PCRE2."

	^ substitutionCount
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> version [

	^ version
]
