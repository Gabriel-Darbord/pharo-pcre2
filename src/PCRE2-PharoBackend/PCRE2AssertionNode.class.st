Class {
	#name : 'PCRE2AssertionNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'predicate',
		'kind'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'parsing' }
PCRE2AssertionNode >> canBeRepeated [

	^ false
]

{ #category : 'matching' }
PCRE2AssertionNode >> executeIn: anEngine state: aState [

	^ (predicate value: anEngine value: aState)
		  ifTrue: [ aState ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
PCRE2AssertionNode >> kind [

	^ kind
]

{ #category : 'accessing' }
PCRE2AssertionNode >> kind: aSymbol [

	kind := aSymbol
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

	^ (#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [ [ :character | false ] ]
]
