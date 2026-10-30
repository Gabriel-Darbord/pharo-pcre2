"
Alternation. The first branch continues the current state and every other branch is enqueued as a copy of it, so branches are tried in pattern order.
"
Class {
	#name : 'PCRE2AlternativeNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2AlternativeNode >> canAccept [

	^ children anySatisfy: #canAccept
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> children [

	^ children
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> children: anArray [

	children := anArray
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

{ #category : 'optimization' }
PCRE2AlternativeNode >> firstLiteral [

	| first |
	first := children first firstLiteral.
	first ifNil: [ ^ nil ].
	^ (children allSatisfy: [ :child | child firstLiteral = first ]) ifTrue: [ first ]
]

{ #category : 'optimization' }
PCRE2AlternativeNode >> firstLiteralPredicate [

	| predicates |
	self firstLiteral ifNil: [ ^ nil ].
	predicates := children collect: #firstLiteralPredicate.
	(predicates includes: nil) ifTrue: [ ^ nil ].
	^ self startPredicateOf: predicates
]

{ #category : 'optimization' }
PCRE2AlternativeNode >> isAnchoredIn: analysis [

	^ children allSatisfy: [ :branch | branch isAnchoredIn: analysis ]
]

{ #category : 'optimization' }
PCRE2AlternativeNode >> isStartLineIn: analysis [

	^ children allSatisfy: [ :branch | branch isStartLineIn: analysis ]
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> lengthBoundsUsing: groups names: names visited: visited [

	| bounds maximum |
	bounds := children collect: [ :node | node lengthBoundsUsing: groups names: names visited: visited ].
	maximum := bounds collect: #second.
	^ {
		  (bounds collect: #first) min.
		  ((maximum includes: nil) ifFalse: [ maximum max ]) }
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> lookbehindBranches [

	^ children
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> maximumLength [

	| lengths |
	lengths := children collect: #maximumLength.
	(lengths includes: nil) ifTrue: [ ^ nil ].
	^ lengths max
]

{ #category : 'accessing' }
PCRE2AlternativeNode >> minimumLength [

	^ (children collect: #minimumLength) min
]

{ #category : 'optimization' }
PCRE2AlternativeNode >> startPredicate [

	| predicates |
	predicates := children collect: #startPredicate.
	(predicates includes: nil) ifTrue: [ ^ nil ].
	^ self startPredicateOf: predicates
]
