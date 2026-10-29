Class {
	#name : 'PCRE2LookaheadNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child',
		'positive'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2LookaheadNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2LookaheadNode >> child: aValue [

	child := aValue
]

{ #category : 'private' }
PCRE2LookaheadNode >> executeIn: anEngine state: aState [

	| result |
	result := anEngine matchNode: child state: aState.
	positive ifFalse: [ ^ result ifNil: [ aState ] ifNotNil: [ nil ] ].
	result ifNil: [ ^ nil ].
	aState captures: result captures.
	^ aState
]

{ #category : 'matching' }
PCRE2LookaheadNode >> maximumLength [

	^ 0
]

{ #category : 'private' }
PCRE2LookaheadNode >> positive [

	^ positive
]

{ #category : 'private' }
PCRE2LookaheadNode >> positive: aValue [

	positive := aValue
]
