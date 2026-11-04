"
Lookahead assertion, positive or negative. It is atomic by default; the non-atomic forms keep their choice points so the enclosing pattern can backtrack into them.
"
Class {
	#name : 'PCRE2LookaheadNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child',
		'positive',
		'atomic'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2LookaheadNode >> atomic [

	^ atomic
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> atomic: boolean [

	atomic := boolean
]

{ #category : 'testing' }
PCRE2LookaheadNode >> canBeCondition [

	^ atomic ~= false
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> child [

	^ child
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> child: aNode [

	child := aNode
]

{ #category : 'matching' }
PCRE2LookaheadNode >> conditionalIn: engine state: state [

	| result |
	result := engine matchNode: child state: state.
	result ifNotNil: [
			state
				lastCapture: result lastCapture;
				captures: result captures ].
	^ positive = result isNotNil
]

{ #category : 'matching' }
PCRE2LookaheadNode >> executeIn: engine state: state [

	| result |
	atomic = false ifTrue: [ ^ self nonAtomicIn: engine state: state ].
	result := engine matchNode: child state: state propagate: (positive
			           ifTrue: [ #positive ]
			           ifFalse: [ #none ]).
	positive ifFalse: [ ^ result ifNil: [ state ] ifNotNil: [ nil ] ].
	result ifNil: [ ^ nil ].
	state
		lastCapture: result lastCapture;
		captures: result captures;
		mark: result mark.
	^ state
]

{ #category : 'optimization' }
PCRE2LookaheadNode >> isAnchoredIn: analysis [
	"A branch that opens with a positive lookahead starts wherever the lookahead does. A negative one says nothing."

	^ positive and: [ child isAnchoredIn: analysis withinAssertion ]
]

{ #category : 'optimization' }
PCRE2LookaheadNode >> isStartLineIn: analysis [

	^ positive and: [ child isStartLineIn: analysis withinAssertion ]
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2LookaheadNode >> nonAtomicIn: engine state: state [

	| end |
	end := PCRE2LookaroundEndNode new position: state position assertions: state assertions alternations: state alternations.
	state
		assertions: {
				engine choiceDepth.
				state assertions };
		alternations: nil.
	state
		push: end;
		push: child.
	^ state
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> positive [

	^ positive
]

{ #category : 'accessing' }
PCRE2LookaheadNode >> positive: aBoolean [

	positive := aBoolean
]

{ #category : 'optimization' }
PCRE2LookaheadNode >> startPredicate [

	^ [ :character | false ]
]

{ #category : 'generating' }
PCRE2LookaheadNode >> writeInto: aGenerator at: position indent: level then: aBlock [

	^ aGenerator
		  writeLookahead: self
		  at: position
		  indent: level
		  then: aBlock
]
