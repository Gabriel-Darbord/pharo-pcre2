Extension { #name : 'PCRE2CalloutEvent' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> fromCalloutBlock: anExternalAddress [

	^ self fromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> fromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	^ self new initializeFromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent >> initializeFromCalloutBlock: anExternalAddress [

	^ self initializeFromCalloutBlock: anExternalAddress codeUnitWidth: 8
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent >> initializeFromCalloutBlock: anExternalAddress codeUnitWidth: codeUnitWidth [

	| offsetVectorOffset pointerOffset sizeOffset wordSize |
	wordSize := ExternalAddress wordSize.
	offsetVectorOffset := 16.
	sizeOffset := offsetVectorOffset + (3 * wordSize).

	version := anExternalAddress uint32AtOffset: 0.
	number := anExternalAddress uint32AtOffset: 4.
	captureTop := anExternalAddress uint32AtOffset: 8.
	captureLast := anExternalAddress uint32AtOffset: 12.
	offsets := self class offsetsFrom: (anExternalAddress pointerAtOffset: offsetVectorOffset) count: captureTop * 2.
	mark := PCRE2CalloutSite
		        zeroTerminatedStringFrom: (anExternalAddress pointerAtOffset: offsetVectorOffset + wordSize)
		        codeUnitWidth: codeUnitWidth.
	subjectLength := self class sizeTFrom: anExternalAddress atOffset: sizeOffset.
	startMatch := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + wordSize.
	currentPosition := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (2 * wordSize).
	patternPosition := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (3 * wordSize).
	nextItemLength := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (4 * wordSize).
	stringOffset := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (5 * wordSize).
	stringLength := self class sizeTFrom: anExternalAddress atOffset: sizeOffset + (6 * wordSize).
	pointerOffset := sizeOffset + (7 * wordSize).
	string := self class
		          stringFrom: (anExternalAddress pointerAtOffset: pointerOffset)
		          length: stringLength
		          codeUnitWidth: codeUnitWidth.
	flags := anExternalAddress uint32AtOffset: pointerOffset + wordSize
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> offsetsFrom: anExternalAddress count: count [

	| values wordSize |
	(anExternalAddress isNil or: [ anExternalAddress isNull ]) ifTrue: [ ^ #(  ) ].
	values := Array new: count.
	wordSize := ExternalAddress wordSize.
	1 to: count do: [ :index | values at: index put: (self sizeTFrom: anExternalAddress atOffset: wordSize * (index - 1)) ].
	^ values
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> sizeTFrom: anExternalAddress atOffset: structOffsetInBytes [

	^ PCRE2CalloutSite sizeTFrom: anExternalAddress atOffset: structOffsetInBytes
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> stringFrom: anExternalAddress length: length [

	^ PCRE2CalloutSite stringFrom: anExternalAddress length: length
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2CalloutEvent class >> stringFrom: anExternalAddress length: length codeUnitWidth: codeUnitWidth [

	^ PCRE2CalloutSite stringFrom: anExternalAddress length: length codeUnitWidth: codeUnitWidth
]
