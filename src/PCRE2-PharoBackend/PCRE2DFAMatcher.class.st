Class {
	#name : 'PCRE2DFAMatcher',
	#superclass : 'PCRE2BacktrackingMatcher',
	#instVars : [
		'shortest',
		'autoPossessEnabled',
		'suppressPossession'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2DFAMatcher >> allMatches: initialState [

	| seen queue results key state node |
	seen := Set new.
	queue := OrderedCollection with: initialState.
	results := OrderedCollection new.
	choices := OrderedCollection new.
	[ queue isNotEmpty ] whileTrue: [
			state := queue removeFirst.
			key := state dfaKey.
			(seen includes: key) ifFalse: [
					seen add: key.
					state tasks
						ifNil: [
								(self acceptsEndOf: state) ifTrue: [
									(results anySatisfy: [ :previous | previous position = state position ]) ifFalse: [ results add: state ] ] ]
						ifNotNil: [
								depthLimit ifNotNil: [
									state pendingDepth > depthLimit ifTrue: [ PCRE2MatchError signal: 'matching depth limit exceeded' ] ].
								steps := steps + 1.
								steps > limit ifTrue: [ PCRE2MatchError signal: 'match limit exceeded' ].
								node := state pop.
								node dfaError = 0 ifFalse: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: node dfaError) ].
								state := self executeNode: node state: state.
								state ifNotNil: [ queue add: state ].
								queue addAll: choices.
								choices removeAll ] ] ].
	^ results sorted: [ :left :right | left position > right position ]
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> autoPossess: repeat state: state [

	| link predicate literal |
	(autoPossessEnabled = true and: [ suppressPossession ~= true and: [ repeat greedy and: [ repeat child canAutoPossess ] ] ])
		ifFalse: [ ^ false ].
	link := state tasks.
	literal := repeat child literalCharacter.
	[ link isNotNil ] whileTrue: [
			link first maximumLength = 0 ifFalse: [
					literal ifNil: [ ^ false ].
					predicate := link first startPredicate.
					predicate ifNil: [ ^ false ].
					((PCRE2UnicodeData equivalents: literal asInteger) anySatisfy: [ :code | predicate value: (Character value: code) ]) ifTrue: [
						^ false ].
					link first minimumLength > 0 ifTrue: [ ^ true ] ].
			link := link second ].
	^ true
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> autoPossessEnabled: boolean [

	autoPossessEnabled := boolean
]

{ #category : 'callouts' }
PCRE2DFAMatcher >> callout: site state: state [

	| eventState result |
	eventState := state copy
		              captures: (Array new: state captures size withAll: PCRE2 unsetOffset);
		              lastCapture: 0.
	eventState captures at: 1 put: state captures first.
	calloutFlags := 0.
	result := super callout: site state: eventState.
	^ result ifNotNil: [ state ]
]

{ #category : 'matching' }
PCRE2DFAMatcher >> executeNode: node state: state [

	node dfaError = 0 ifFalse: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: node dfaError) ].
	^ node executeIn: self state: state
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> matchNode: node state: state propagate: mode [

	| savedChoices savedShortest nested results |
	mode = #atomic ifFalse: [ mode = #possess ifFalse: [ ^ super matchNode: node state: state propagate: mode ] ].
	savedChoices := choices.
	savedShortest := shortest.
	nested := state copy
		          tasks: nil;
		          alternations: nil;
		          push: node.
	[ results := self allMatches: nested ] ensure: [
			choices := savedChoices.
			shortest := savedShortest ].
	results ifEmpty: [ ^ nil ].
	^ (mode = #possess or: [ shortest ~= true ])
		  ifTrue: [ results first ]
		  ifFalse: [ results last ]
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> possessRepeat: node state: state [

	| saved result |
	saved := suppressPossession.
	suppressPossession := true.
	[ result := self matchNode: node state: state propagate: #possess ] ensure: [ suppressPossession := saved ].
	result ifNil: [ ^ nil ].
	result
		tasks: state tasks;
		alternations: state alternations.
	^ result
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> shortest: boolean [

	shortest := boolean
]
