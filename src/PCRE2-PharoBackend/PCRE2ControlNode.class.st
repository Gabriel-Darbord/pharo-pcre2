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

{ #category : 'matching' }
PCRE2ControlNode >> boundary: aFrame [

	boundary := aFrame
]

{ #category : 'optimization' }
PCRE2ControlNode >> canAccept [

	^ kind = #accept
]

{ #category : 'DFA matching' }
PCRE2ControlNode >> dfaError [

	^ kind = #fail
		  ifTrue: [ 0 ]
		  ifFalse: [ -42 ]
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

{ #category : 'matching' }
PCRE2ControlNode >> kind: aSymbol name: aName [

	kind := aSymbol.
	name := aName
]

{ #category : 'matching' }
PCRE2ControlNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ #( 0 0 )
]

{ #category : 'matching' }
PCRE2ControlNode >> maximumLength [

	^ kind = #accept ifFalse: [ 0 ]
]

{ #category : 'diagnostics' }
PCRE2ControlNode >> runtimeStorageSize [

	^ kind = #backtrack
		  ifTrue: [ self sizeInMemory + boundary sizeInMemory ]
		  ifFalse: [ 0 ]
]

{ #category : 'matching' }
PCRE2ControlNode >> startPredicate [

	kind = #accept ifTrue: [ ^ nil ].
	^ [ :character | false ]
]

{ #category : 'matching' }
PCRE2ControlNode >> terminatesWithAccept [

	^ kind = #accept
]
