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
		'depthLimit'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> acceptsEndOf: aState [

	((self matchOptions bitAnd: PCRE2 endAnchored) ~= 0 and: [ aState position ~= subject size ]) ifTrue: [ ^ false ].
	aState position = aState captures first ifFalse: [ ^ true ].
	(self matchOptions bitAnd: PCRE2 notEmpty) ~= 0 ifTrue: [ ^ false ].
	^ (self matchOptions bitAnd: PCRE2 notEmptyAtStart) = 0 or: [ aState position ~= initialPosition ]
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> captureIndexFor: reference [

	^ reference isInteger
		  ifTrue: [ reference ]
		  ifFalse: [ names keyAtValue: reference ifAbsent: [ nil ] ]
]

{ #category : 'configuration' }
PCRE2BacktrackingMatcher >> depthLimit: anInteger [

	depthLimit := anInteger
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> enqueue: aState [

	choices add: aState
]

{ #category : 'private' }
PCRE2BacktrackingMatcher >> groupFor: reference [

	| index |
	index := self captureIndexFor: reference.
	index = 0 ifTrue: [ ^ root ].
	^ groups at: index ifAbsent: [ PCRE2MatchError signal: 'Unknown subroutine' ]
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> initialPosition [

	^ initialPosition
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> initialPosition: anInteger [

	initialPosition := anInteger
]

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> matchNode: aNode state: aState [

	| savedChoices savedOptions nested result |
	savedChoices := choices.
	savedOptions := matchOptions.
	nested := aState copy.
	nested
		tasks: nil;
		push: aNode.
	matchOptions := 0.
	[ result := self run: nested ] ensure: [
			choices := savedChoices.
			matchOptions := savedOptions ].
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

{ #category : 'accessing' }
PCRE2BacktrackingMatcher >> run: aState [

	| state node |
	choices := OrderedCollection with: aState.
	[ choices isEmpty ] whileFalse: [
			state := choices removeLast.
			[ state notNil ] whileTrue: [
					state tasks ifNil: [
							(self acceptsEndOf: state) ifTrue: [ ^ state ].
							state := nil ].
					state ifNotNil: [
							(depthLimit isNotNil and: [ state pendingDepth > depthLimit ]) ifTrue: [
								PCRE2MatchError signal: 'matching depth limit exceeded' ].
							steps := steps + 1.
							steps > limit ifTrue: [ PCRE2MatchError signal: 'match limit exceeded' ].
							node := state pop.
							state := node executeIn: self state: state ] ] ].
	^ nil
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
