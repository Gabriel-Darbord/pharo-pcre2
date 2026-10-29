Class {
	#name : 'PCRE2AssertionNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'predicate'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2AssertionNode >> executeIn: anEngine state: aState [

	^ (predicate value: anEngine value: aState)
		  ifTrue: [ aState ]
		  ifFalse: [ nil ]
]

{ #category : 'matching' }
PCRE2AssertionNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2AssertionNode >> predicate: aBlock [

	predicate := aBlock
]

{ #category : 'matching' }
PCRE2AssertionNode >> startPredicate [

	^ [ :character | false ]
]
