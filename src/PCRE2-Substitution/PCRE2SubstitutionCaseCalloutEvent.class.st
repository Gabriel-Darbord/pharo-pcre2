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
	#category : 'PCRE2-Substitution',
	#package : 'PCRE2-Substitution'
}

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

{ #category : 'initialization' }
PCRE2SubstitutionCaseCalloutEvent >> inputText: text length: length capacity: capacity caseType: type codeUnitWidth: width [

	inputText := text.
	inputLength := length.
	outputCapacity := capacity.
	caseType := type.
	codeUnitWidth := width
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
	^ aString first asUppercase asString , aString allButFirst asLowercase
]
