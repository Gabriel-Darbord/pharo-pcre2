"
Executes pattern nodes with an explicit stack of alternatives. Pending tasks use immutable linked pairs; branch copies retain their own capture arrays. Nested assertions save the outer choice stack. Work and pending-depth limits bound execution.
"
Class {
	#name : 'PCRE2BacktrackingMatcher',
	#superclass : 'Object',
	#instVars : [
		'subject',
		'root',
		'groups',
		'names',
		'choices',
		'steps',
		'limit',
		'matchOptions',
		'initialPosition',
		'depthLimit',
		'committed',
		'skipPosition',
		'lastMark',
		'failureControl',
		'callBase',
		'partialState',
		'hardPartialFound',
		'calloutBlock',
		'codeUnitMapping',
		'calloutFlags',
		'abortedCode',
		'heapLimit',
		'queuedStorage',
		'outerStates',
		'candidateStart',
		'earliestConsulted'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'callouts' }
PCRE2BacktrackingMatcher >> abortedCode [

	^ abortedCode
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> accept: state [

	[ state tasks isNotNil ] whileTrue: [ (state pop acceptIn: self state: state) ifTrue: [ ^ state ] ].
	state accepted: true.
	^ state
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> acceptsEndOf: aState [

	((self matchOptions bitAnd: PCRE2 endAnchored) ~= 0 and: [ aState position ~= subject size ]) ifTrue: [ ^ false ].
	aState position = aState captures first ifFalse: [ ^ true ].
	(self matchOptions bitAnd: PCRE2 notEmpty) ~= 0 ifTrue: [ ^ false ].
	^ (self matchOptions bitAnd: PCRE2 notEmptyAtStart) = 0 or: [ aState position ~= initialPosition ]
]

{ #category : 'DFA matching' }
PCRE2BacktrackingMatcher >> autoPossess: repeat state: state [

	^ false
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> backtrack: kind boundary: frame state: state [

	| depth |
	kind = #then ifTrue: [
			depth := frame second
				         ifNil: [ state assertions ifNil: [ 0 ] ifNotNil: [ :assertion | assertion first ] ]
				         ifNotNil: [ :alternation | alternation first ].
			(frame second isNil and: [ state assertions isNil ]) ifTrue: [
					failureControl := {
						                  kind.
						                  frame first } ].
			self trimChoicesTo: depth.
			^ self ].
	(state subroutines isNotNil and: [ state subroutines ~~ callBase ]) ifTrue: [
			self trimChoicesTo: state subroutines third.
			^ self ].
	failureControl := {
		                  kind.
		                  frame first }.
	self trimChoicesTo: 0.
	kind = #commit ifTrue: [ committed := true ].
	kind = #skip ifTrue: [ skipPosition := frame first ]
]

{ #category : 'callouts' }
PCRE2BacktrackingMatcher >> beginMatch [

	calloutFlags := PCRE2 calloutStartMatch
]

{ #category : 'callouts' }
PCRE2BacktrackingMatcher >> beginMatchAt: position [

	calloutFlags := PCRE2 calloutStartMatch.
	candidateStart := position.
	earliestConsulted := position
]

{ #category : 'callouts' }
PCRE2BacktrackingMatcher >> callout: site state: state [

	| event result values |
	calloutBlock ifNil: [ ^ state ].
	values := state captures collect: [ :offset |
			          offset = PCRE2 unsetOffset
				          ifTrue: [ offset ]
				          ifFalse: [ codeUnitMapping at: offset + 1 ] ].
	values
		at: 1 put: PCRE2 unsetOffset;
		at: 2 put: PCRE2 unsetOffset.
	event := PCRE2CalloutEvent new
		         initializeSite: site
		         captures: values
		         captureLast: state lastCapture
		         start: (codeUnitMapping at: candidateStart + 1)
		         position: (codeUnitMapping at: state position + 1)
		         subjectLength: codeUnitMapping last
		         flags: calloutFlags
		         mark: state mark.
	calloutFlags := 0.
	result := calloutBlock value: event.
	result isInteger ifFalse: [ ^ state ].
	result = 0 ifTrue: [ ^ state ].
	result < 0 ifTrue: [
			abortedCode := result.
			choices removeAll ].
	^ nil
]

{ #category : 'callouts' }
PCRE2BacktrackingMatcher >> calloutBlock: block mapping: mapping [

	calloutBlock := block.
	codeUnitMapping := mapping.
	calloutFlags := PCRE2 calloutStartMatch
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> captureIndexFor: reference [

	| indexes |
	reference isInteger ifTrue: [ ^ reference ].
	indexes := names keys select: [ :index | (names at: index) = reference ].
	^ indexes ifNotEmpty: [ indexes min ]
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> captureIndexFor: reference state: state [

	| indexes |
	reference isInteger ifTrue: [ ^ reference ].
	indexes := (names keys select: [ :index | (names at: index) = reference ]) sorted.
	^ indexes
		  detect: [ :index | (state captures at: index * 2 + 2) ~= PCRE2 unsetOffset ]
		  ifNone: [ indexes ifNotEmpty: [ indexes first ] ]
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> captureIsSet: reference state: state [

	reference isInteger ifTrue: [ ^ (state captures at: reference * 2 + 2) ~= PCRE2 unsetOffset ].
	names keysAndValuesDo: [ :index :name |
		(name = reference and: [ (state captures at: index * 2 + 2) ~= PCRE2 unsetOffset ]) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'limits' }
PCRE2BacktrackingMatcher >> checkHeapFor: state [

	| estimate seen size outer |
	heapLimit ifNil: [ ^ self ].
	estimate := (queuedStorage ifNil: [ 0 ]) + state matchingStorageUpperBound.
	outer := outerStates.
	[ outer isNotNil ] whileTrue: [
			estimate := estimate + outer first matchingStorageUpperBound + outer second.
			outer := outer third ].
	estimate <= heapLimit ifTrue: [ ^ self ].
	seen := IdentitySet new.
	size := state matchingStorageIn: seen.
	choices do: [ :choice | size := size + (choice matchingStorageIn: seen) ].
	outer := outerStates.
	[ outer isNotNil ] whileTrue: [
			size := size + (outer first matchingStorageIn: seen).
			outer fourth do: [ :choice | size := size + (choice matchingStorageIn: seen) ].
			outer := outer third ].
	size > heapLimit ifTrue: [ PCRE2MatchError signal: 'heap limit exceeded' ]
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> choiceDepth [

	^ choices size
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> committed [

	^ committed = true
]

{ #category : 'configuration' }
PCRE2BacktrackingMatcher >> depthLimit: anInteger [

	depthLimit := anInteger
]

{ #category : 'limits' }
PCRE2BacktrackingMatcher >> enqueue: state [

	choices add: state.
	queuedStorage := (queuedStorage ifNil: [ 0 ]) + state matchingStorageUpperBound
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> executeNode: node state: state [

	^ node executeIn: self state: state
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> groupFor: reference [

	| index |
	index := self captureIndexFor: reference.
	index = 0 ifTrue: [ ^ root ].
	^ groups at: index ifAbsent: [ PCRE2MatchError signal: 'Unknown subroutine' ]
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> hardPartialFound [

	^ hardPartialFound = true
]

{ #category : 'limits' }
PCRE2BacktrackingMatcher >> heapLimit: kibibytes [

	heapLimit := kibibytes * 1024
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> initialPosition [

	^ initialPosition
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> initialPosition: anInteger [

	initialPosition := anInteger
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> isRecursing: reference state: state [

	state subroutines ifNil: [ ^ false ].
	reference ifNil: [ ^ true ].
	reference isInteger ifTrue: [ ^ state subroutines first = reference ].
	^ (names at: state subroutines first ifAbsent: [ nil ]) = reference
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> lastMark [

	^ lastMark
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> lastMark: value [

	lastMark := value
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> matchNode: node state: state [

	^ self matchNode: node state: state propagate: #none
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> matchNode: node state: state propagate: mode [

	| savedChoices savedOptions savedCommit savedSkip savedFailure savedBase nested result failure savedStorage savedOuter |
	savedChoices := choices.
	savedStorage := queuedStorage.
	savedOuter := outerStates.
	outerStates := {
		               state.
		               (queuedStorage ifNil: [ 0 ]).
		               outerStates.
		               choices }.
	savedOptions := matchOptions.
	savedCommit := committed.
	savedSkip := skipPosition.
	savedFailure := failureControl.
	savedBase := callBase.
	nested := state copy.
	nested
		tasks: nil;
		alternations: nil;
		assertions: nil;
		push: node.
	matchOptions := matchOptions bitAnd: PCRE2 notBOL | PCRE2 notEOL | PCRE2 partialSoft | PCRE2 partialHard.
	[
		result := self run: nested.
		failure := failureControl ] ensure: [
			choices := savedChoices.
			queuedStorage := savedStorage.
			outerStates := savedOuter.
			matchOptions := savedOptions.
			committed := savedCommit.
			skipPosition := savedSkip.
			failureControl := savedFailure.
			callBase := savedBase ].
	(result isNil and: [ failure isNotNil and: [ mode = #atomic or: [ mode = #positive and: [ failure first ~= #then ] ] ] ])
		ifTrue: [
				self
					backtrack: failure first
					boundary: {
							failure second.
							state alternations.
							0 }
					state: state ].
	^ result
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> matchOptions [

	^ matchOptions ifNil: [ 0 ]
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> matchOptions: anInteger [

	matchOptions := anInteger
]

{ #category : 'limits' }
PCRE2BacktrackingMatcher >> nextChoice [

	| state |
	state := choices removeLast.
	queuedStorage := (queuedStorage ifNil: [ 0 ]) - state matchingStorageUpperBound.
	^ state
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> noteInspectionAt: position [

	earliestConsulted ifNil: [ earliestConsulted := position ].
	earliestConsulted := earliestConsulted min: position
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> notePartial: state [

	| candidate |
	(self matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ifTrue: [ ^ self ].
	(state position > candidateStart or: [ earliestConsulted < candidateStart or: [ root minimumLength = 0 ] ]) ifFalse: [ ^ self ].
	candidate := state copy tasks: nil.
	candidate captures
		at: 1 put: candidateStart;
		at: 2 put: subject size.
	partialState ifNil: [ partialState := candidate ].
	(self matchOptions bitAnd: PCRE2 partialHard) ~= 0 ifTrue: [ hardPartialFound := true ]
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> partialState [

	^ partialState
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> run: aState [

	| state node firstChoice |
	firstChoice := true.
	choices := OrderedCollection new.
	queuedStorage := 0.
	self enqueue: aState.
	committed := false.
	failureControl := nil.
	callBase := aState subroutines.
	skipPosition := nil.
	[ choices isEmpty ] whileFalse: [
			firstChoice ifFalse: [ calloutFlags := calloutFlags bitOr: PCRE2 calloutBacktrack ].
			firstChoice := false.
			state := self nextChoice.
			[ state notNil ] whileTrue: [
					state tasks ifNil: [
							(state accepted or: [ self acceptsEndOf: state ]) ifTrue: [ ^ state ].
							state := nil ].
					state ifNotNil: [
							(depthLimit isNotNil and: [ state pendingDepth > depthLimit ]) ifTrue: [
								PCRE2MatchError signal: 'matching depth limit exceeded' ].
							steps := steps + 1.
							steps > limit ifTrue: [ PCRE2MatchError signal: 'match limit exceeded' ].
							self checkHeapFor: state.
							node := state pop.
							state := self executeNode: node state: state.
							self hardPartialFound ifTrue: [ ^ nil ] ] ] ].
	^ nil
]

{ #category : 'matching' }
PCRE2BacktrackingMatcher >> skipPosition [

	^ skipPosition
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> subject [

	^ subject
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> subject: aString root: aNode groups: groupNodes names: captureNames limit: aLimit [

	subject := aString.
	root := aNode.
	groups := groupNodes.
	names := captureNames.
	limit := aLimit.
	steps := 0
]

{ #category : 'limits' }
PCRE2BacktrackingMatcher >> trimChoicesTo: depth [

	[ choices size > depth ] whileTrue: [ self nextChoice ]
]
