Class {
	#name : 'PCRE2AlternativeNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2AlternativeNode >> canAccept [

	^ children anySatisfy: #canAccept
]

{ #category : 'private' }
PCRE2AlternativeNode >> children [

	^ children
]

{ #category : 'private' }
PCRE2AlternativeNode >> children: aValue [

	children := aValue
]

{ #category : 'matching' }
PCRE2AlternativeNode >> executeIn: engine state: state [

	| previous end alternative |
	previous := state alternations.
	end := PCRE2AlternativeEndNode new previous: previous.
	children size to: 2 by: -1 do: [ :index |
			alternative := state copy.
			alternative alternations: {
					engine choiceDepth.
					previous }.
			alternative
				push: end;
				push: (children at: index).
			engine enqueue: alternative ].
	state alternations: {
			engine choiceDepth.
			previous }.
	state
		push: end;
		push: children first.
	^ state
]

{ #category : 'matching' }
PCRE2AlternativeNode >> firstLiteral [

	| first |
	first := children first firstLiteral.
	first ifNil: [ ^ nil ].
	^ (children allSatisfy: [ :child | child firstLiteral = first ]) ifTrue: [ first ]
]

{ #category : 'matching' }
PCRE2AlternativeNode >> lengthBoundsUsing: groups names: names visited: visited [

	| bounds maximum |
	bounds := children collect: [ :node | node lengthBoundsUsing: groups names: names visited: visited ].
	maximum := bounds collect: #second.
	^ {
		  (bounds collect: #first) min.
		  ((maximum includes: nil) ifFalse: [ maximum max ]) }
]

{ #category : 'matching' }
PCRE2AlternativeNode >> lookbehindBranches [

	^ children
]

{ #category : 'matching' }
PCRE2AlternativeNode >> maximumLength [

	| lengths |
	lengths := children collect: #maximumLength.
	(lengths includes: nil) ifTrue: [ ^ nil ].
	^ lengths max
]

{ #category : 'matching' }
PCRE2AlternativeNode >> minimumLength [

	^ (children collect: #minimumLength) min
]

{ #category : 'matching' }
PCRE2AlternativeNode >> startPredicate [

	| predicates |
	predicates := children collect: #startPredicate.
	(predicates includes: nil) ifTrue: [ ^ nil ].
	^ [ :character | predicates anySatisfy: [ :test | test value: character ] ]
]
