"
Zero-width assertion such as \b, \B, \A, \z, \Z, \G or \K, decided by a predicate on the engine and the state. Its kind names which one it is; multiline says whether it was compiled to see line ends.
"
Class {
	#name : 'PCRE2AssertionNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'predicate',
		'kind',
		'multiline',
		'byteTest'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2AssertionNode >> byteTest: anArray [

	byteTest := anArray
]

{ #category : 'testing' }
PCRE2AssertionNode >> canBeRepeated [

	^ false
]

{ #category : 'matching' }
PCRE2AssertionNode >> executeIn: anEngine state: aState [

	^ (predicate value: anEngine value: aState) ifTrue: [ aState ]
]

{ #category : 'optimization' }
PCRE2AssertionNode >> isAnchoredIn: analysis [
	"\A and \G pin a match to one place, and so does ^ unless it was compiled to see line ends."

	^ kind = #beginSubject or: [ kind = #startMatch or: [ kind = #beginLine and: [ multiline not ] ] ]
]

{ #category : 'optimization' }
PCRE2AssertionNode >> isStartLineIn: analysis [

	^ kind = #beginLine
]

{ #category : 'accessing' }
PCRE2AssertionNode >> kind [

	^ kind
]

{ #category : 'accessing' }
PCRE2AssertionNode >> kind: aSymbol [

	kind := aSymbol
]

{ #category : 'accessing' }
PCRE2AssertionNode >> maximumLength [

	^ 0
]

{ #category : 'accessing' }
PCRE2AssertionNode >> multiline: aBoolean [

	multiline := aBoolean
]

{ #category : 'accessing' }
PCRE2AssertionNode >> predicate: aBlock [

	predicate := aBlock
]

{ #category : 'optimization' }
PCRE2AssertionNode >> startPredicate [
	"\b, \B and ^ outside multiline mode contribute no character, so the scan looks past them. Every other kind answers nil, giving up as PCRE2 does, so both backends attempt the same positions."

	(#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [ ^ [ :character | false ] ].
	^ (kind = #beginLine and: [ multiline not ]) ifTrue: [ [ :character | false ] ]
]

{ #category : 'generating' }
PCRE2AssertionNode >> writeInto: aGenerator at: position then: aBlock [

	^ aGenerator writeAssertion: byteTest at: position then: aBlock
]
