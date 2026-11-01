"
Zero-width assertion decided by a predicate on the engine and the state, such as \b, \B, \A, \z, \Z, \G and \K. The kind names which one it is, and multiline says whether it was compiled to see line ends, which the start optimizations ask about as well as matching.
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
PCRE2AssertionNode >> byteTest [
	"How a written matcher can decide this assertion by reading bytes, or nil when it cannot. Chosen when the pattern is parsed, where the options that change what the assertion means are known."

	^ byteTest
]

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
	"What this assertion contributes to the characters a match may start with. It consumes nothing, so it contributes none and the scan looks past it. PCRE2 gives up on every other kind instead, and a pattern whose starting characters are unknown is attempted at every position, so following that choice is what keeps the two backends attempting the same positions."

	(#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [ ^ [ :character | false ] ].
	^ (kind = #beginLine and: [ multiline not ]) ifTrue: [ [ :character | false ] ]
]

{ #category : 'generating' }
PCRE2AssertionNode >> writeInto: aGenerator at: position indent: level then: aBlock [

	^ aGenerator
		  writeAssertion: byteTest
		  at: position
		  indent: level
		  then: aBlock
]
