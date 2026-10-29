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

{ #category : 'matching' }
PCRE2LookaheadNode >> atomic: boolean [

	atomic := boolean
]

{ #category : 'matching' }
PCRE2LookaheadNode >> canBeCondition [

	^ atomic ~= false
]

{ #category : 'private' }
PCRE2LookaheadNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2LookaheadNode >> child: aValue [

	child := aValue
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

{ #category : 'DFA matching' }
PCRE2LookaheadNode >> dfaError [

	^ atomic = false
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
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

{ #category : 'matching' }
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

{ #category : 'private' }
PCRE2LookaheadNode >> positive [

	^ positive
]

{ #category : 'private' }
PCRE2LookaheadNode >> positive: aValue [

	positive := aValue
]

{ #category : 'matching' }
PCRE2LookaheadNode >> startPredicate [

	^ [ :character | false ]
]
