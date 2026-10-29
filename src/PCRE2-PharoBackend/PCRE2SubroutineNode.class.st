Class {
	#name : 'PCRE2SubroutineNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'reference',
		'retainedGroups'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2SubroutineNode >> canAccept [

	^ true
]

{ #category : 'matching' }
PCRE2SubroutineNode >> executeIn: engine state: state [

	| index frame |
	index := engine captureIndexFor: reference.
	frame := state subroutines.
	[ frame isNotNil ] whileTrue: [
			(frame first = index and: [
					 frame fourth = state position and: [
						 frame fifth = engine lastInspected and: [ (engine matchOptions bitAnd: PCRE2 disableRecurseloopCheck) = 0 ] ] ]) ifTrue: [
				PCRE2MatchError signal: 'nested recursion at the same subject position' ].
			frame := frame second ].
	state push: (PCRE2SubroutineReturnNode new
			 captures: state captures copy;
			 alternations: state alternations;
			 retainedGroups: ((retainedGroups ifNil: [ #(  ) ]) flatCollect: [ :each |
						  (engine captureIndexesFor: each) reject: [ :retained | retained = index ] ]);
			 lastCapture: state lastCapture;
			 subroutines: state subroutines).
	state subroutines: {
			index.
			state subroutines.
			engine choiceDepth.
			state position.
			engine lastInspected }.
	state alternations: nil.
	state push: (engine groupFor: reference).
	^ state
]

{ #category : 'matching' }
PCRE2SubroutineNode >> lengthBoundsUsing: groups names: names visited: visited [

	| index target |
	index := reference isInteger
		         ifTrue: [ reference ]
		         ifFalse: [ names keyAtValue: reference ifAbsent: [ nil ] ].
	target := groups at: index ifAbsent: [ ^ { 0. nil } ].
	^ target lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'private' }
PCRE2SubroutineNode >> reference [

	^ reference
]

{ #category : 'private' }
PCRE2SubroutineNode >> reference: aValue [

	reference := aValue
]

{ #category : 'accessing' }
PCRE2SubroutineNode >> retainedGroups: references [

	retainedGroups := references
]
