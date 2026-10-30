"
Assertion that the match is at one remembered subject position. Lookbehind plants it behind a branch to pin the branch to where the assertion was entered.
"
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

	^ aState position = position ifTrue: [ aState ]
]

{ #category : 'accessing' }
PCRE2PositionAssertionNode >> position: anInteger [

	position := anInteger
]
