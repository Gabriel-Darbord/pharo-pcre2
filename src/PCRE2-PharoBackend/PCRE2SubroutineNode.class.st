"
Subroutine call to a group, by number as in (?1) or by name as in (?&name). The group matches on its own and the captures are restored on return, except for the groups the call asks to retain.
"
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

{ #category : 'testing' }
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

{ #category : 'accessing' }
PCRE2SubroutineNode >> lengthBoundsUsing: groups names: names visited: visited [

	| index target |
	index := reference isInteger
		         ifTrue: [ reference ]
		         ifFalse: [ names keyAtValue: reference ifAbsent: [ nil ] ].
	target := groups at: index ifAbsent: [ ^ { 0. nil } ].
	^ target lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'accessing' }
PCRE2SubroutineNode >> reference [

	^ reference
]

{ #category : 'accessing' }
PCRE2SubroutineNode >> reference: aReference [

	reference := aReference
]

{ #category : 'accessing' }
PCRE2SubroutineNode >> retainedGroups: references [

	retainedGroups := references
]
