"
Lookbehind assertion, positive or negative. Every branch carries the length bounds the parser computed for it, and the engine starts the branch that many characters back and pins it to the current position.
"
Class {
	#name : 'PCRE2LookbehindNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'branches',
		'positive',
		'branchBounds',
		'atomic'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2LookbehindNode >> atomic [

	^ atomic
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> atomic: boolean [

	atomic := boolean
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> branchBounds: bounds [

	branchBounds := bounds
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> branches [

	^ branches
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> branches: anArray [

	branches := anArray
]

{ #category : 'testing' }
PCRE2LookbehindNode >> canBeCondition [

	^ atomic ~= false
]

{ #category : 'matching' }
PCRE2LookbehindNode >> conditionalIn: engine state: state [

	| target |
	target := state position.
	branches do: [ :branch |
			| sequence |
			sequence := PCRE2SequenceNode new children: {
					            branch.
					            (PCRE2PositionAssertionNode new position: target) }.
			(engine subject lookbehindStartsMinimum: (self minimumLengthFor: branch) maximum: (self maximumLengthFor: branch) at: target)
				do: [ :start |
						| result |
						result := engine matchNode: sequence state: (state copy position: start).
						result ifNotNil: [
								state
									lastCapture: result lastCapture;
									captures: result captures.
								^ positive ] ] ].
	^ positive not
]

{ #category : 'DFA matching' }
PCRE2LookbehindNode >> dfaError [

	^ atomic = false
		  ifTrue: [ -42 ]
		  ifFalse: [ 0 ]
]

{ #category : 'matching' }
PCRE2LookbehindNode >> executeIn: engine state: state [

	| result target |
	atomic = false ifTrue: [ ^ self nonAtomicIn: engine state: state ].
	target := state position.
	branches do: [ :branch |
			| sequence |
			sequence := PCRE2SequenceNode new children: {
					            branch.
					            (PCRE2PositionAssertionNode new position: target) }.
			(engine subject lookbehindStartsMinimum: (self minimumLengthFor: branch) maximum: (self maximumLengthFor: branch) at: target)
				do: [ :start |
						result := engine matchNode: sequence state: (state copy position: start) propagate: (positive
								           ifTrue: [ #positive ]
								           ifFalse: [ #none ]).
						result ifNotNil: [
								positive ifFalse: [ ^ nil ].
								state
									lastCapture: result lastCapture;
									captures: result captures;
									mark: result mark.
								^ state ] ] ].
	^ positive ifFalse: [ state ]
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> maximumLength [

	^ 0
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> maximumLengthFor: branch [

	^ (branchBounds at: branch) second
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> minimumLengthFor: branch [

	^ (branchBounds at: branch) first
]

{ #category : 'matching' }
PCRE2LookbehindNode >> nonAtomicIn: engine state: state [

	| candidates target next |
	candidates := OrderedCollection new.
	target := state position.
	branches do: [ :branch |
			(engine subject lookbehindStartsMinimum: (self minimumLengthFor: branch) maximum: (self maximumLengthFor: branch) at: target)
				do: [ :start |
						next := state copy
							        position: start;
							        assertions: {
									        engine choiceDepth.
									        state assertions };
							        alternations: nil.
						next
							push: (PCRE2LookaroundEndNode new position: target assertions: state assertions alternations: state alternations);
							push: (PCRE2PositionAssertionNode new position: target);
							push: branch.
						candidates add: next ] ].
	candidates ifEmpty: [ ^ nil ].
	candidates size to: 2 by: -1 do: [ :index | engine enqueue: (candidates at: index) ].
	^ candidates first
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> positive [

	^ positive
]

{ #category : 'accessing' }
PCRE2LookbehindNode >> positive: aBoolean [

	positive := aBoolean
]

{ #category : 'optimization' }
PCRE2LookbehindNode >> startPredicate [

	^ [ :character | false ]
]

{ #category : 'generating' }
PCRE2LookbehindNode >> writeInto: aGenerator at: position indent: level then: aBlock [

	^ aGenerator
		  writeLookbehind: self
		  at: position
		  indent: level
		  then: aBlock
]
