"
The engine that runs a compiled pattern over a subject for the Pharo backend.

It drives the standard PCRE2 algorithm: `run:` takes states off the choice stack, pops one task from each and lets the node execute itself, so a node never recurses into the engine. `PCRE2DFAMatchEngine` reuses all of this and replaces only the search around it, which is why it is a subclass rather than a sibling: it still runs nested assertions through `run:`.

My state is the registers of that loop, in groups:

- the match: subject, originalSubject, root, groups, names, matchOptions, initialPosition
- the search: choices, outerStates, steps
- control verbs: committed, failureControl, skipPosition, lastMark, callBase
- partial matching: partialState, hardPartialFound, candidateStart, earliestConsulted, lastInspected, allowEmptyPartial
- callouts: calloutBlock, codeUnitMapping, calloutFlags, abortedCode
- limits: limit, depthLimit, heapLimit, queuedStorage

`subject` follows the state being run, since a scan-substring assertion narrows it; `originalSubject` is what the match was started on.
"
Class {
	#name : 'PCRE2MatchEngine',
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
		'earliestConsulted',
		'originalSubject',
		'lastInspected',
		'allowEmptyPartial'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2MatchEngine >> abortedCode [

	^ abortedCode
]

{ #category : 'matching' }
PCRE2MatchEngine >> accept: state [

	[ state tasks isNotNil ] whileTrue: [ (state pop acceptIn: self state: state) ifTrue: [ ^ state ] ].
	self trimChoicesTo: 0.
	state accepted: true.
	^ state
]

{ #category : 'accessing' }
PCRE2MatchEngine >> acceptsEndOf: aState [

	((self matchOptions bitAnd: PCRE2 endAnchored) ~= 0 and: [ aState position ~= subject size ]) ifTrue: [ ^ false ].
	aState position = aState captures first ifFalse: [ ^ true ].
	(self matchOptions bitAnd: PCRE2 notEmpty) ~= 0 ifTrue: [ ^ false ].
	^ (self matchOptions bitAnd: PCRE2 notEmptyAtStart) = 0 or: [ aState position ~= initialPosition ]
]

{ #category : 'accessing' }
PCRE2MatchEngine >> allowEmptyPartial: aBoolean [
	"Whether PCRE2 counts a partial match that has consumed nothing, which it does for a pattern that looks behind or can match an empty string."

	allowEmptyPartial := aBoolean
]

{ #category : 'optimization' }
PCRE2MatchEngine >> autoPossess: repeat state: state [

	^ false
]

{ #category : 'matching' }
PCRE2MatchEngine >> backtrack: kind boundary: frame state: state [

	| depth |
	kind = #then ifTrue: [
			(state subroutines isNotNil and: [ state subroutines ~~ callBase and: [ frame second isNil ] ]) ifTrue: [
					self trimChoicesTo: state subroutines third.
					^ self ].
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
PCRE2MatchEngine >> beginMatchAt: position [

	calloutFlags := PCRE2 calloutStartMatch.
	candidateStart := position.
	earliestConsulted := position
]

{ #category : 'callouts' }
PCRE2MatchEngine >> callout: site state: state [

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
PCRE2MatchEngine >> calloutBlock: block mapping: mapping [

	calloutBlock := block.
	codeUnitMapping := mapping.
	calloutFlags := PCRE2 calloutStartMatch
]

{ #category : 'matching' }
PCRE2MatchEngine >> captureIndexFor: reference [

	| indexes |
	reference isInteger ifTrue: [ ^ reference ].
	indexes := names keys select: [ :index | (names at: index) = reference ].
	^ indexes ifNotEmpty: [ indexes min ]
]

{ #category : 'matching' }
PCRE2MatchEngine >> captureIndexFor: reference state: state [

	| indexes |
	reference isInteger ifTrue: [ ^ reference ].
	indexes := (names keys select: [ :index | (names at: index) = reference ]) sorted.
	^ indexes
		  detect: [ :index | (state captures at: index * 2 + 2) ~= PCRE2 unsetOffset ]
		  ifNone: [ indexes ifNotEmpty: [ indexes first ] ]
]

{ #category : 'matching' }
PCRE2MatchEngine >> captureIndexesFor: reference [

	reference isInteger ifTrue: [ ^ { reference } ].
	^ (names keys select: [ :index | (names at: index) = reference ]) sorted
]

{ #category : 'matching' }
PCRE2MatchEngine >> captureIsSet: reference state: state [

	reference isInteger ifTrue: [ ^ (state captures at: reference * 2 + 2) ~= PCRE2 unsetOffset ].
	names keysAndValuesDo: [ :index :name |
		(name = reference and: [ (state captures at: index * 2 + 2) ~= PCRE2 unsetOffset ]) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'limits' }
PCRE2MatchEngine >> checkHeapFor: state [

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

{ #category : 'choices' }
PCRE2MatchEngine >> choiceDepth [

	^ choices size
]

{ #category : 'matching' }
PCRE2MatchEngine >> committed [

	^ committed = true
]

{ #category : 'accessing' }
PCRE2MatchEngine >> depthLimit: anInteger [

	depthLimit := anInteger
]

{ #category : 'choices' }
PCRE2MatchEngine >> enqueue: state [
	"Keep a choice to come back to. The heap is checked here, where the storage grows, rather than on every step."

	choices add: state.
	queuedStorage := (queuedStorage ifNil: [ 0 ]) + state matchingStorageUpperBound.
	self checkHeapFor: state
]

{ #category : 'matching' }
PCRE2MatchEngine >> executeNode: node state: state [

	^ node executeIn: self state: state
]

{ #category : 'private' }
PCRE2MatchEngine >> groupFor: reference [

	| index |
	index := self captureIndexFor: reference.
	index = 0 ifTrue: [ ^ root ].
	^ groups at: index ifAbsent: [ PCRE2MatchError signal: 'Unknown subroutine' ]
]

{ #category : 'matching' }
PCRE2MatchEngine >> hardPartialFound [

	^ hardPartialFound
]

{ #category : 'limits' }
PCRE2MatchEngine >> heapLimit: kibibytes [

	heapLimit := kibibytes * 1024
]

{ #category : 'accessing' }
PCRE2MatchEngine >> initialPosition [

	^ initialPosition
]

{ #category : 'accessing' }
PCRE2MatchEngine >> initialPosition: anInteger [

	initialPosition := anInteger
]

{ #category : 'initialization' }
PCRE2MatchEngine >> initialize [

	hardPartialFound := false
]

{ #category : 'matching' }
PCRE2MatchEngine >> isRecursing: reference state: state [

	state subroutines ifNil: [ ^ false ].
	reference ifNil: [ ^ true ].
	reference isInteger ifTrue: [ ^ state subroutines first = reference ].
	^ (names at: state subroutines first ifAbsent: [ nil ]) = reference
]

{ #category : 'accessing' }
PCRE2MatchEngine >> lastInspected [

	^ lastInspected ifNil: [ 0 ]
]

{ #category : 'accessing' }
PCRE2MatchEngine >> lastMark [

	^ lastMark
]

{ #category : 'accessing' }
PCRE2MatchEngine >> lastMark: value [

	lastMark := value
]

{ #category : 'matching' }
PCRE2MatchEngine >> matchNode: node state: state [

	^ self matchNode: node state: state propagate: #none
]

{ #category : 'matching' }
PCRE2MatchEngine >> matchNode: node state: state propagate: mode [

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
	matchOptions := matchOptions bitAnd:
		                PCRE2 notBOL | PCRE2 notEOL | PCRE2 partialSoft | PCRE2 partialHard | PCRE2 disableRecurseloopCheck.
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
PCRE2MatchEngine >> matchOptions [

	^ matchOptions ifNil: [ 0 ]
]

{ #category : 'accessing' }
PCRE2MatchEngine >> matchOptions: anInteger [

	matchOptions := anInteger
]

{ #category : 'choices' }
PCRE2MatchEngine >> nextChoice [

	| state |
	state := choices removeLast.
	queuedStorage := (queuedStorage ifNil: [ 0 ]) - state matchingStorageUpperBound.
	^ state
]

{ #category : 'matching' }
PCRE2MatchEngine >> noteEndOfSubject: state [
	"An assertion answered what it did only because the subject ends where it does. PCRE2 counts that however little the attempt has consumed."

	| candidate |
	state subjectText ifNotNil: [ ^ self ].
	(self matchOptions bitAnd: PCRE2 partialSoft | PCRE2 partialHard) = 0 ifTrue: [ ^ self ].
	candidate := state copy tasks: nil.
	candidate captures
		at: 1 put: candidateStart;
		at: 2 put: subject size.
	partialState ifNil: [ partialState := candidate ].
	(self matchOptions bitAnd: PCRE2 partialHard) ~= 0 ifTrue: [ hardPartialFound := true ]
]

{ #category : 'matching' }
PCRE2MatchEngine >> noteInspectionAt: position [

	earliestConsulted ifNil: [ earliestConsulted := position ].
	earliestConsulted := earliestConsulted min: position.
	lastInspected := self lastInspected max: position + (position < subject size
			                  ifTrue: [ subject pointWidthAtOffset: position ]
			                  ifFalse: [ 0 ])
]

{ #category : 'matching' }
PCRE2MatchEngine >> notePartial: state [
	"The matcher ran out of subject here. PCRE2 counts it only once the attempt has consumed something or read behind its start, unless the pattern allows an empty partial match."

	(state position > candidateStart or: [ earliestConsulted < candidateStart or: [ allowEmptyPartial = true ] ]) ifTrue: [
		self noteEndOfSubject: state ]
]

{ #category : 'accessing' }
PCRE2MatchEngine >> partialState [

	^ partialState
]

{ #category : 'private' }
PCRE2MatchEngine >> prepareRunFor: aState [
	"Clear the state one run leaves behind, then make aState the only choice."

	choices := OrderedCollection new.
	queuedStorage := 0.
	committed := false.
	failureControl := nil.
	callBase := aState subroutines.
	skipPosition := nil.
	self enqueue: aState
]

{ #category : 'matching' }
PCRE2MatchEngine >> run: aState [

	| state node firstChoice |
	self prepareRunFor: aState.
	firstChoice := true.
	[ choices isEmpty ] whileFalse: [
			firstChoice ifFalse: [ calloutFlags := calloutFlags bitOr: PCRE2 calloutBacktrack ].
			firstChoice := false.
			state := self nextChoice.
			[ state isNotNil ] whileTrue: [
					subject := state subjectText ifNil: [ originalSubject ].
					state tasks ifNil: [
							(self acceptsEndOf: state) ifTrue: [ ^ state ].
							state := nil ].
					state ifNotNil: [
							(depthLimit isNotNil and: [ state pendingDepth > depthLimit ]) ifTrue: [
								PCRE2MatchError signal: 'matching depth limit exceeded' ].
							steps := steps + 1.
							steps > limit ifTrue: [ PCRE2MatchError signal: 'match limit exceeded' ].
							node := state pop.
							state := self executeNode: node state: state.
							hardPartialFound ifTrue: [ ^ nil ] ] ] ].
	^ nil
]

{ #category : 'optimization' }
PCRE2MatchEngine >> scanRepeat: node state: aState [
	"Count off a repetition of single characters in one step, then keep the shorter runs as one choice. A run only moves forward, so of everything the engine records about what was read, only the first and the last position matter. Counting the run costs no steps, as in PCRE2, where the match limit counts backtracks rather than characters."

	| scan count read next |
	scan := node child countIn: self from: aState position limit: node maximum.
	count := scan first.
	read := scan third.
	read ifNotNil: [
			self noteInspectionAt: aState position.
			self noteInspectionAt: read ].
	aState position: scan second.
	((node maximum isNil or: [ count < node maximum ]) and: [ scan second >= subject size ]) ifTrue: [ self notePartial: aState ].
	count < node minimum ifTrue: [ ^ nil ].
	count > node minimum ifTrue: [
			next := aState copy.
			next push: (PCRE2CharacterRepeatFrame new
					 repeat: node;
					 count: count).
			self enqueue: next ].
	^ aState
]

{ #category : 'accessing' }
PCRE2MatchEngine >> scanSubjectTo: end [

	^ originalSubject prefixTo: end
]

{ #category : 'optimization' }
PCRE2MatchEngine >> scansRepeats [
	"Whether a repetition of single characters may be counted off in one step. The DFA matcher answers no: it follows every alternative at once and needs each turn of a repetition as a state of its own."

	^ true
]

{ #category : 'accessing' }
PCRE2MatchEngine >> skipPosition [

	^ skipPosition
]

{ #category : 'accessing' }
PCRE2MatchEngine >> subject [

	^ subject
]

{ #category : 'private' }
PCRE2MatchEngine >> subject: aString root: aNode groups: groupNodes names: captureNames limit: aLimit [

	subject := aString.
	originalSubject := aString.
	root := aNode.
	groups := groupNodes.
	names := captureNames.
	limit := aLimit.
	steps := 0
]

{ #category : 'choices' }
PCRE2MatchEngine >> trimChoicesTo: depth [

	[ choices size > depth ] whileTrue: [ self nextChoice ]
]
