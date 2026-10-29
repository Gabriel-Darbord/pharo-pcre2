Class {
	#name : 'PCRE2SubroutineReturnNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'captures'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> captures: anArray [

	captures := anArray
]

{ #category : 'matching' }
PCRE2SubroutineReturnNode >> executeIn: anEngine state: aState [

	| restored |
	restored := captures copy.
	restored at: 1 put: aState captures first.
	aState captures: restored.
	^ aState
]
