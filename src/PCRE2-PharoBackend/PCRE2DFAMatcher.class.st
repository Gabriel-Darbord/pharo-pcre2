Class {
	#name : 'PCRE2DFAMatcher',
	#superclass : 'PCRE2BacktrackingMatcher',
	#instVars : [
		'shortest',
		'autoPossessEnabled',
		'suppressPossession',
		'restartStates',
		'currentState',
		'workspaceLimit',
		'allowEmptyPartial'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> allMatches: initialState [

	^ self allMatchesFrom: { initialState }
]

{ #category : 'matching' }
PCRE2DFAMatcher >> allMatchesFrom: initialStates [

	| seen queue results key state node savedCurrent |
	seen := Set new.
	queue := initialStates asOrderedCollection.
	results := OrderedCollection new.
	choices := OrderedCollection new.
	[ queue isNotEmpty ] whileTrue: [
			workspaceLimit ifNotNil: [ queue size > workspaceLimit ifTrue: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: -43) ] ].
			state := queue removeFirst.
			key := state dfaKey.
			(seen includes: key) ifFalse: [
					seen add: key.
					state tasks
						ifNil: [
								(state position = subject size and: [ (self matchOptions bitAnd: PCRE2 partialHard | PCRE2 partialSoft) ~= 0 ]) ifTrue: [
										restartStates ifNil: [ restartStates := OrderedCollection new ].
										restartStates add: state copy ].
								(self acceptsEndOf: state) ifTrue: [
									(results anySatisfy: [ :previous | previous position = state position ]) ifFalse: [ results add: state ] ] ]
						ifNotNil: [
								depthLimit ifNotNil: [
									state pendingDepth > depthLimit ifTrue: [ PCRE2MatchError signal: 'matching depth limit exceeded' ] ].
								steps := steps + 1.
								steps > limit ifTrue: [ PCRE2MatchError signal: 'match limit exceeded' ].
								savedCurrent := currentState.
								currentState := state copy.
								node := state pop.
								[ state := self executeNode: node state: state ] ensure: [ currentState := savedCurrent ].
								state ifNotNil: [ queue add: state ].
								queue addAll: choices.
								choices removeAll ] ] ].
	^ results sorted: [ :left :right | left position > right position ]
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> allowEmptyPartial: aBoolean [

	allowEmptyPartial := aBoolean
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
					((PCRE2UnicodeData equivalents: literal asInteger) anySatisfy: [ :code | predicate value: (PCRE2CodeUnit fromInteger: code) ])
						ifTrue: [ ^ false ].
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

	| result hard |
	node dfaError = 0 ifFalse: [ PCRE2MatchError signal: (PCRE2 translateErrorCode: node dfaError) ].
	hard := (self matchOptions bitAnd: PCRE2 partialHard) ~= 0.
	state position = subject size ifTrue: [
			(node isKindOf: PCRE2LookbehindNode) ifTrue: [
					self notePartial: state.
					hard ifTrue: [ ^ nil ] ].
			(node isKindOf: PCRE2AssertionNode) ifTrue: [
					(#( wordBoundary notWordBoundary ) includes: node kind) ifTrue: [ self notePartial: state ].
					((#( endLine endSubject endBeforeFinalNewline ) includes: node kind) and: [ hard ]) ifTrue: [
							self notePartial: state.
							^ nil ] ] ].
	result := node executeIn: self state: state.
	^ result
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> matchNode: node state: state propagate: mode [

	| savedChoices savedShortest nested results savedRestart nestedRestart |
	mode = #atomic ifFalse: [ mode = #possess ifFalse: [ ^ super matchNode: node state: state propagate: mode ] ].
	savedChoices := choices.
	savedShortest := shortest.
	savedRestart := restartStates.
	restartStates := nil.
	nested := state copy
		          tasks: nil;
		          alternations: nil;
		          push: node.
	[
		results := self allMatches: nested.
		nestedRestart := restartStates ] ensure: [
			choices := savedChoices.
			shortest := savedShortest.
			restartStates := savedRestart ].
	nestedRestart ifNotNil: [
			restartStates ifNil: [ restartStates := OrderedCollection new ].
			(mode = #possess or: [ node isKindOf: PCRE2RepeatNode ])
				ifTrue: [
						nestedRestart do: [ :continuation |
								continuation appendTasks: state tasks.
								restartStates add: continuation ] ]
				ifFalse: [
						((nestedRestart anySatisfy: [ :continuation | continuation tasks isNotNil ]) and: [ currentState isNotNil ]) ifTrue: [
							restartStates add: (currentState copy position: subject size) ] ] ].
	results ifEmpty: [ ^ nil ].
	^ (mode = #possess or: [ shortest ~= true ])
		  ifTrue: [ results first ]
		  ifFalse: [ results last ]
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> notePartial: state [

	| continuation |
	allowEmptyPartial = true ifTrue: [ earliestConsulted := candidateStart - 1 ].
	super notePartial: state.
	(partialState isNil or: [ currentState isNil ]) ifTrue: [ ^ self ].
	continuation := ((currentState tasks first isKindOf: PCRE2GraphemeNode) and: [ state position > currentState position ])
		                ifTrue: [ state copy ]
		                ifFalse: [ currentState copy ].
	restartStates ifNil: [ restartStates := OrderedCollection new ].
	(restartStates anySatisfy: [ :previous |
			 previous dfaKey = continuation dfaKey or: [
					 previous tasks isNotNil and: [
						 (previous tasks first isKindOf: PCRE2LookbehindNode) and: [ previous tasks second == continuation tasks ] ] ] ]) ifFalse: [
		restartStates add: continuation ]
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
PCRE2DFAMatcher >> restartStates [

	^ (restartStates ifNil: [ #(  ) ]) collect: [ :state | state copy restartAfter: subject size ]
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> shortest: boolean [

	shortest := boolean
]

{ #category : 'DFA matching' }
PCRE2DFAMatcher >> workspaceLimit: size [

	workspaceLimit := size
]
