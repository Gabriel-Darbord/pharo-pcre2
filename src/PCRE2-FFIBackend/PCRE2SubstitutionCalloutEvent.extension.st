Extension { #name : 'PCRE2SubstitutionCalloutEvent' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> alignedOffsetAfterUInt32ForWordSize: wordSize [
	"Answer the first pointer-field offset after a uint32_t in the native struct, measured in bytes."

	^ 4 + wordSize - 1 // wordSize * wordSize
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> fromCalloutBlock: anExternalAddress [

	^ self fromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> fromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	^ self new initializeFromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent >> initializeFromCalloutBlock: anExternalAddress [

	^ self initializeFromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent >> initializeFromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	| inputPointer outputPointer ovectorPointer outputOffsetsOffset ovectorPointerOffset pointerOffset wordSize |
	wordSize := ExternalAddress wordSize.
	pointerOffset := self class alignedOffsetAfterUInt32ForWordSize: wordSize.
	outputOffsetsOffset := pointerOffset + (2 * wordSize).
	ovectorPointerOffset := outputOffsetsOffset + (2 * wordSize).

	version := anExternalAddress uint32AtOffset: 0.
	inputPointer := anExternalAddress pointerAtOffset: pointerOffset.
	outputPointer := anExternalAddress pointerAtOffset: pointerOffset + wordSize.
	outputOffsets := {
		                 (self class sizeTFrom: anExternalAddress atOffset: outputOffsetsOffset).
		                 (self class sizeTFrom: anExternalAddress atOffset: outputOffsetsOffset + wordSize) }.
	ovectorPointer := anExternalAddress pointerAtOffset: ovectorPointerOffset.
	ovectorCount := anExternalAddress uint32AtOffset: ovectorPointerOffset + wordSize.
	substitutionCount := anExternalAddress uint32AtOffset: ovectorPointerOffset + wordSize + 4.
	offsets := self class offsetsFrom: ovectorPointer count: ovectorCount * 2.
	matchedText := offsets isEmpty ifFalse: [
			               self class
				               stringFrom: inputPointer
				               startOffset: offsets first
				               endOffset: offsets second
				               codeUnitWidth: codeUnitWidth ].
	replacementText := self class
		                   stringFrom: outputPointer
		                   startOffset: outputOffsets first
		                   endOffset: outputOffsets second
		                   codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> offsetsFrom: anExternalAddress count: count [

	^ PCRE2CalloutEvent offsetsFrom: anExternalAddress count: count
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> sizeTFrom: anExternalAddress atOffset: structOffsetInBytes [
	"Read a PCRE2_SIZE field from a native substitution-callout struct. The ExternalAddress offset is measured in bytes."

	^ PCRE2CalloutEvent sizeTFrom: anExternalAddress atOffset: structOffsetInBytes
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCalloutEvent class >> stringFrom: anExternalAddress startOffset: startOffset endOffset: endOffset codeUnitWidth: codeUnitWidth [
	"Decode a substring addressed by PCRE2_SIZE code-unit offsets."

	| bytes byteStart byteSize length unitSize |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [ ^ nil ].
	(startOffset = PCRE2 unsetOffset or: [ endOffset = PCRE2 unsetOffset ]) ifTrue: [ ^ nil ].
	length := endOffset - startOffset.
	length <= 0 ifTrue: [ ^ '' ].
	unitSize := codeUnitWidth // 8.
	byteStart := startOffset * unitSize.
	byteSize := length * unitSize.
	bytes := ByteArray new: byteSize.
	1 to: byteSize do: [ :index | bytes at: index put: (anExternalAddress uint8AtOffset: byteStart + index - 1) ].
	^ PCRE2CalloutSite stringFromBytes: bytes codeUnitWidth: codeUnitWidth
]
