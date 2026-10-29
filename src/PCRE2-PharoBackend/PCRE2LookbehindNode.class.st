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

{ #category : 'matching' }
PCRE2LookbehindNode >> atomic: boolean [

	atomic := boolean
]

{ #category : 'matching' }
PCRE2LookbehindNode >> branchBounds: bounds [

	branchBounds := bounds
]

{ #category : 'matching' }
PCRE2LookbehindNode >> branches: anArray [

	branches := anArray
]

{ #category : 'matching' }
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
			(target - (self maximumLengthFor: branch) max: 0) to: target - (self minimumLengthFor: branch) do: [ :start |
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
PCRE2LookbehindNode >> executeIn: anEngine state: aState [

	| result target |
	atomic = false ifTrue: [ ^ self nonAtomicIn: anEngine state: aState ].
	target := aState position.
	branches do: [ :branch |
			| sequence |
			sequence := PCRE2SequenceNode new children: {
					            branch.
					            (PCRE2PositionAssertionNode new position: target) }.
			(target - (self maximumLengthFor: branch) max: 0) to: target - (self minimumLengthFor: branch) do: [ :start |
					| before |
					before := aState copy position: start.
					result := anEngine matchNode: sequence state: before propagate: (positive
							           ifTrue: [ #positive ]
							           ifFalse: [ #none ]).
					result ifNotNil: [
							positive ifFalse: [ ^ nil ].
							aState
								lastCapture: result lastCapture;
								captures: result captures;
								mark: result mark.
							^ aState ] ] ].
	^ positive ifFalse: [ aState ]
]

{ #category : 'matching' }
PCRE2LookbehindNode >> maximumLength [

	^ 0
]

{ #category : 'matching' }
PCRE2LookbehindNode >> maximumLengthFor: branch [

	^ (branchBounds at: branch) second
]

{ #category : 'matching' }
PCRE2LookbehindNode >> minimumLengthFor: branch [

	^ (branchBounds at: branch) first
]

{ #category : 'matching' }
PCRE2LookbehindNode >> nonAtomicIn: engine state: state [

	| candidates target next |
	candidates := OrderedCollection new.
	target := state position.
	branches do: [ :branch |
			(target - (self maximumLengthFor: branch) max: 0) to: target - (self minimumLengthFor: branch) do: [ :start |
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

{ #category : 'matching' }
PCRE2LookbehindNode >> positive: aBoolean [

	positive := aBoolean
]

{ #category : 'matching' }
PCRE2LookbehindNode >> startPredicate [

	^ [ :character | false ]
]
