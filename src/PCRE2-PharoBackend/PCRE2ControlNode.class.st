"
Backtracking control verb: (*ACCEPT), (*FAIL), (*MARK), (*COMMIT), (*PRUNE), (*SKIP) and (*THEN). The verbs that cut back enqueue a failure continuation saying how far the engine unwinds when what follows fails.
"
Class {
	#name : 'PCRE2ControlNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'kind',
		'name',
		'boundary'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2ControlNode >> boundary: aFrame [

	boundary := aFrame
]

{ #category : 'testing' }
PCRE2ControlNode >> canAccept [

	^ kind = #accept
]

{ #category : 'testing' }
PCRE2ControlNode >> canBeRepeated [

	^ kind = #accept
]

{ #category : 'matching' }
PCRE2ControlNode >> executeIn: engine state: state [

	| failure point mark |
	kind = #fail ifTrue: [ ^ nil ].
	kind = #accept ifTrue: [ ^ engine accept: state ].
	kind = #mark ifTrue: [
			state
				mark: name;
				marks: {
						name.
						state position.
						state marks.
						((state marks ifNil: [ 0 ] ifNotNil: [ :previous | previous fourth ]) + 1) }.
			engine lastMark: name.
			^ state ].
	kind = #backtrack ifTrue: [
			engine backtrack: name boundary: boundary state: state.
			^ nil ].
	point := state position.
	(kind = #skip and: [ name isNotNil ]) ifTrue: [
			mark := state marks.
			[ mark isNotNil and: [ mark first ~= name ] ] whileTrue: [ mark := mark third ].
			mark ifNil: [ ^ state ].
			point := mark second ].
	name ifNotNil: [
			state mark: name.
			engine lastMark: name ].
	failure := state copy tasks: nil.
	failure push: (self class new
			 kind: #backtrack name: kind;
			 boundary: {
					 point.
					 state alternations.
					 engine choiceDepth }).
	engine enqueue: failure.
	^ state
]

{ #category : 'optimization' }
PCRE2ControlNode >> isSignificantForStart [
	"PCRE2 looks past a verb that only leaves a name behind, and stops at every other one, (*ACCEPT:NAME) included."

	^ name isNil or: [ (#( mark commit prune skip then ) includes: kind) not ]
]

{ #category : 'matching' }
PCRE2ControlNode >> kind: aSymbol name: aName [

	kind := aSymbol.
	name := aName
]

{ #category : 'accessing' }
PCRE2ControlNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ #( 0 0 )
]

{ #category : 'accessing' }
PCRE2ControlNode >> maximumLength [

	^ kind = #accept ifFalse: [ 0 ]
]

{ #category : 'diagnostics' }
PCRE2ControlNode >> runtimeStorageSize [

	^ kind = #backtrack
		  ifTrue: [ self sizeInMemory + boundary sizeInMemory ]
		  ifFalse: [ 0 ]
]

{ #category : 'testing' }
PCRE2ControlNode >> terminatesWithAccept [

	^ kind = #accept
]
