"
Atomic group: the child matches in a nested run whose choice points are dropped once it succeeds, so the enclosing pattern never backtracks into it. A possessive quantifier compiles to one too, flagged as possessive because PCRE2 analyses it as a quantifier rather than as a group.
"
Class {
	#name : 'PCRE2AtomicNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child',
		'possessive'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2AtomicNode >> analysisWithin: analysis [
	"PCRE2 analyses a possessive quantifier as the plain repetition, but nothing leading inside an atomic group says where a match can begin."

	^ possessive = true
		  ifTrue: [ analysis ]
		  ifFalse: [ analysis withinAtomicGroup ]
]

{ #category : 'testing' }
PCRE2AtomicNode >> canAccept [

	^ child canAccept
]

{ #category : 'accessing' }
PCRE2AtomicNode >> child [

	^ child
]

{ #category : 'accessing' }
PCRE2AtomicNode >> child: aNode [

	child := aNode
]

{ #category : 'matching' }
PCRE2AtomicNode >> executeIn: engine state: state [

	| result |
	result := engine matchNode: child state: state propagate: #atomic.
	result ifNil: [ ^ nil ].
	result
		tasks: state tasks;
		alternations: state alternations;
		marks: state marks.
	result accepted ifTrue: [
			result accepted: false.
			^ engine accept: result ].
	^ result
]

{ #category : 'optimization' }
PCRE2AtomicNode >> firstLiteral [

	^ child firstLiteral
]

{ #category : 'optimization' }
PCRE2AtomicNode >> firstLiteralPredicate [

	^ child firstLiteralPredicate
]

{ #category : 'optimization' }
PCRE2AtomicNode >> isAnchoredIn: analysis [

	^ child isAnchoredIn: (self analysisWithin: analysis)
]

{ #category : 'optimization' }
PCRE2AtomicNode >> isStartLineIn: analysis [

	^ child isStartLineIn: (self analysisWithin: analysis)
]

{ #category : 'accessing' }
PCRE2AtomicNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ child lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'accessing' }
PCRE2AtomicNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'accessing' }
PCRE2AtomicNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'accessing' }
PCRE2AtomicNode >> possessive: aBoolean [

	possessive := aBoolean
]

{ #category : 'optimization' }
PCRE2AtomicNode >> requiredNode [

	^ child requiredNode
]

{ #category : 'optimization' }
PCRE2AtomicNode >> startPredicate [

	^ child startPredicate
]

{ #category : 'generating' }
PCRE2AtomicNode >> writeInto: aGenerator at: position then: aBlock [
	"A possessive quantifier is the repetition it was written on."

	^ possessive = true
		  ifTrue: [ child writePossessivelyInto: aGenerator at: position then: aBlock ]
		  ifFalse: [ aGenerator writeAtomic: child at: position then: aBlock ]
]
