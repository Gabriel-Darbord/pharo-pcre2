Class {
	#name : 'PCRE2SubroutineNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'reference'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2SubroutineNode >> executeIn: anEngine state: aState [

	aState push: (PCRE2SubroutineReturnNode new captures: aState captures copy).
	aState push: (anEngine groupFor: reference).
	^ aState
]

{ #category : 'private' }
PCRE2SubroutineNode >> reference [

	^ reference
]

{ #category : 'private' }
PCRE2SubroutineNode >> reference: aValue [

	reference := aValue
]
