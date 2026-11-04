Extension { #name : 'PCRE2SubstitutionCaseCalloutEvent' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCaseCalloutEvent class >> bytesForString: aString codeUnitWidth: codeUnitWidth [

	codeUnitWidth = 8 ifTrue: [ ^ (PCRE2UTF8Input fromString: aString) bytes asByteArray ].
	codeUnitWidth = 16 ifTrue: [ ^ (PCRE2UTF16Input fromString: aString) bytes ].
	codeUnitWidth = 32 ifTrue: [ ^ (PCRE2UTF32Input fromString: aString) bytes ].
	PCRE2Error signal: 'Unsupported PCRE2 substitution case code-unit width'
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCaseCalloutEvent class >> copyBytes: bytes to: outputPointer [
	"The caller has already checked the capacity."

	(outputPointer isNil or: [ outputPointer isNull ]) ifTrue: [ ^ self ].
	1 to: bytes size do: [ :index | outputPointer uint8AtOffset: index - 1 put: (bytes at: index) ]
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCaseCalloutEvent class >> fromInput: inputPointer length: inputLength outputCapacity: outputCapacity caseType: caseType codeUnitWidth: codeUnitWidth [

	^ self new
		  initializeFromInput: inputPointer
		  length: inputLength
		  outputCapacity: outputCapacity
		  caseType: caseType
		  codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCaseCalloutEvent >> initializeFromInput: inputPointer length: anInputLength outputCapacity: anOutputCapacity caseType: aCaseType codeUnitWidth: aCodeUnitWidth [

	inputLength := anInputLength.
	outputCapacity := anOutputCapacity.
	caseType := aCaseType.
	codeUnitWidth := aCodeUnitWidth.
	inputText := self class stringFrom: inputPointer length: inputLength codeUnitWidth: codeUnitWidth
]

{ #category : '*PCRE2-FFIBackend' }
PCRE2SubstitutionCaseCalloutEvent class >> stringFrom: inputPointer length: inputLength codeUnitWidth: codeUnitWidth [

	^ PCRE2CalloutSite stringFrom: inputPointer length: inputLength codeUnitWidth: codeUnitWidth
]
