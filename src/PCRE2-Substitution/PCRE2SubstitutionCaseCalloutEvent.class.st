"
I am a snapshot of a substitution case callout, made for each case escape (\U, \L, \u, \l) of a replacement: the text to transform, the operation, and the output capacity. The block answers the transformed string; the match context encodes it to the code-unit width and copies it to the output when it fits.
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

	self isLowercase ifTrue: [ ^ #lowercase ].
	self isUppercase ifTrue: [ ^ #uppercase ].
	self isTitleFirst ifTrue: [ ^ #titleFirst ].
	^ #unknown
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> caseType [

	^ caseType
]

{ #category : 'accessing' }
PCRE2SubstitutionCaseCalloutEvent >> codeUnitWidth [

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

	aString isEmpty ifTrue: [ ^ aString copy ].
	^ aString first asUppercase asString , aString allButFirst asLowercase
]
