Class {
	#name : 'PCRE2PositionAssertionNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'position'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2PositionAssertionNode >> executeIn: anEngine state: aState [

	^ aState position = position
		  ifTrue: [ aState ]
		  ifFalse: [ nil ]
]

{ #category : 'matching' }
PCRE2PositionAssertionNode >> position: anInteger [

	position := anInteger
]
