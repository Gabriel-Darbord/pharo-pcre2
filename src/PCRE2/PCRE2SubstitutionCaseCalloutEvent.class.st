"
I am a snapshot of a PCRE2 substitution case callout.

PCRE2 creates me while processing replacement case escapes such as \U, \L, \u, and \l in pcre2_substitute(). I expose the text PCRE2 wants to case-transform, the requested case operation, and the output capacity supplied by PCRE2.

User blocks should answer the transformed string. The match context callback handles encoding the answer back to the active PCRE2 code-unit width and copying it into PCRE2's output buffer when it fits.
"
Class {
	#name : 'PCRE2SubstitutionCaseCalloutEvent',
	#superclass : 'Object',
	#instVars : [
		'inputText',
		'inputLength',
		'outputCapacity',
		'caseType',
		'codeUnitWidth'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'private' }
PCRE2SubstitutionCaseCalloutEvent class >> bytesForString: aString codeUnitWidth: codeUnitWidth [
	"Encode aString for the active PCRE2 code-unit width."

	codeUnitWidth = 8 ifTrue: [
		^ (PCRE2UTF8Input fromString: aString) bytes asByteArray ].
	codeUnitWidth = 16 ifTrue: [
		^ (PCRE2UTF16Input fromString: aString) bytes ].
	codeUnitWidth = 32 ifTrue: [
		^ (PCRE2UTF32Input fromString: aString) bytes ].
	PCRE2Error signal:
		'Unsupported PCRE2 substitution case code-unit width'
]

{ #category : 'private' }
PCRE2SubstitutionCaseCalloutEvent class >> copyBytes: bytes to: outputPointer [
	"Copy bytes into PCRE2's output buffer. The caller has already checked capacity."

	(outputPointer isNil or: [ outputPointer isNull ]) ifTrue: [ ^ self ].
	1 to: bytes size do: [ :index |
		outputPointer uint8AtOffset: index - 1 put: (bytes at: index) ].
	^ self
]

{ #category : 'instance creation' }
PCRE2SubstitutionCaseCalloutEvent class >> fromInput: inputPointer length: inputLength outputCapacity: outputCapacity caseType: caseType codeUnitWidth: codeUnitWidth [

	^ self new
		  initializeFromInput: inputPointer
		  length: inputLength
		  outputCapacity: outputCapacity
		  caseType: caseType
		  codeUnitWidth: codeUnitWidth
]

{ #category : 'private' }
PCRE2SubstitutionCaseCalloutEvent class >> stringFrom: inputPointer length: inputLength codeUnitWidth: codeUnitWidth [

	^ PCRE2CalloutSite
		  stringFrom: inputPointer
		  length: inputLength
		  codeUnitWidth: codeUnitWidth
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> caseName [
	"Answer a readable name for the requested case transformation."

	self isLowercase ifTrue: [ ^ #lowercase ].
	self isUppercase ifTrue: [ ^ #uppercase ].
	self isTitleFirst ifTrue: [ ^ #titleFirst ].
	^ #unknown
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> caseType [
	"Answer PCRE2's raw substitute-case request constant."

	^ caseType
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> codeUnitWidth [
	"Answer the active PCRE2 code-unit width: 8, 16, or 32."

	^ codeUnitWidth
]

{ #category : 'converting' }
PCRE2SubstitutionCaseCalloutEvent >> defaultTransformedText [
	"Answer Pharo's default transform for the case operation PCRE2 requested."

	self isLowercase ifTrue: [ ^ inputText asLowercase ].
	self isUppercase ifTrue: [ ^ inputText asUppercase ].
	self isTitleFirst ifTrue: [ ^ self titleFirst: inputText ].
	^ inputText
]

{ #category : 'initialization' }
PCRE2SubstitutionCaseCalloutEvent >> initializeFromInput: inputPointer length: anInputLength outputCapacity: anOutputCapacity caseType: aCaseType codeUnitWidth: aCodeUnitWidth [

	inputLength := anInputLength.
	outputCapacity := anOutputCapacity.
	caseType := aCaseType.
	codeUnitWidth := aCodeUnitWidth.
	inputText := self class
		             stringFrom: inputPointer
		             length: inputLength
		             codeUnitWidth: codeUnitWidth.
	^ self
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> inputLength [
	"Answer the input length in PCRE2 code units."

	^ inputLength
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> inputText [
	"Answer the text PCRE2 is asking the callback to case-transform."

	^ inputText
]

{ #category : 'testing' }
PCRE2SubstitutionCaseCalloutEvent >> isLowercase [

	^ caseType = PCRE2 substituteCaseLower
]

{ #category : 'testing' }
PCRE2SubstitutionCaseCalloutEvent >> isTitleFirst [

	^ caseType = PCRE2 substituteCaseTitleFirst
]

{ #category : 'testing' }
PCRE2SubstitutionCaseCalloutEvent >> isUppercase [

	^ caseType = PCRE2 substituteCaseUpper
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> outputCapacity [
	"Answer the output capacity in PCRE2 code units."

	^ outputCapacity
]

{ #category : 'printing' }
PCRE2SubstitutionCaseCalloutEvent >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: self caseName;
		nextPutAll: ', ';
		print: inputText;
		nextPut: $)
]

{ #category : 'private' }
PCRE2SubstitutionCaseCalloutEvent >> titleFirst: aString [
	"Titlecase the first character and lowercase the rest, matching PCRE2's title-first request shape."

	aString isEmpty ifTrue: [ ^ aString copy ].
	^ aString first asUppercase asString
	  , aString allButFirst asLowercase
]
