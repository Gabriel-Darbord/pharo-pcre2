"
A sequence of nodes, pushed so that the first child runs first.
"
Class {
	#name : 'PCRE2SequenceNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2SequenceNode >> canAccept [

	^ children anySatisfy: #canAccept
]

{ #category : 'accessing' }
PCRE2SequenceNode >> children [

	^ children
]

{ #category : 'accessing' }
PCRE2SequenceNode >> children: anArray [

	children := anArray
]

{ #category : 'matching' }
PCRE2SequenceNode >> executeIn: anEngine state: aState [

	children reverseDo: [ :node | aState push: node ].
	^ aState
]

{ #category : 'optimization' }
PCRE2SequenceNode >> firstLiteral [

	children do: [ :child |
			child canAccept ifTrue: [ ^ nil ].
			child maximumLength = 0 ifFalse: [ ^ child firstLiteral ] ].
	^ nil
]

{ #category : 'optimization' }
PCRE2SequenceNode >> firstLiteralPredicate [

	children do: [ :child |
			child canAccept ifTrue: [ ^ nil ].
			child maximumLength = 0 ifFalse: [ ^ child firstLiteralPredicate ] ].
	^ nil
]

{ #category : 'optimization' }
PCRE2SequenceNode >> firstSignificantChild [
	"The first child the start optimizations have to look at, or nil when the branch holds nothing but nodes they pass over."

	^ children detect: [ :child | child isSignificantForStart ] ifNone: [ nil ]
]

{ #category : 'optimization' }
PCRE2SequenceNode >> isAnchoredIn: analysis [

	^ self firstSignificantChild ifNil: [ false ] ifNotNil: [ :child | child isAnchoredIn: analysis ]
]

{ #category : 'optimization' }
PCRE2SequenceNode >> isSignificantForStart [
	"A sequence holding nothing the start optimizations look at, such as the one an inline option setting or a comment leaves behind, is passed over like its children."

	^ self firstSignificantChild isNotNil
]

{ #category : 'optimization' }
PCRE2SequenceNode >> isStartLineIn: analysis [

	^ self firstSignificantChild ifNil: [ false ] ifNotNil: [ :child | child isStartLineIn: analysis ]
]

{ #category : 'accessing' }
PCRE2SequenceNode >> lengthBoundsUsing: groups names: names visited: visited [

	| minimum maximum |
	minimum := 0.
	maximum := 0.
	children do: [ :node |
			| bounds |
			bounds := node lengthBoundsUsing: groups names: names visited: visited.
			minimum := minimum + bounds first.
			maximum := (maximum isNil or: [ bounds second isNil ]) ifFalse: [ maximum + bounds second ].
			node terminatesWithAccept ifTrue: [
					^ {
						  minimum.
						  maximum } ] ].
	^ {
		  minimum.
		  maximum }
]

{ #category : 'accessing' }
PCRE2SequenceNode >> maximumLength [

	| sum |
	sum := 0.
	children do: [ :node | node maximumLength ifNil: [ ^ nil ] ifNotNil: [ :length | sum := sum + length ] ].
	^ sum
]

{ #category : 'accessing' }
PCRE2SequenceNode >> minimumLength [

	| length |
	length := 0.
	children do: [ :child |
			length := length + child minimumLength.
			child canAccept ifTrue: [ ^ length ] ].
	^ length
]

{ #category : 'optimization' }
PCRE2SequenceNode >> requiredNode [

	| required |
	children do: [ :child |
			child requiredNode ifNotNil: [ :node | required := node ].
			child canAccept ifTrue: [ ^ required ] ].
	^ required
]

{ #category : 'optimization' }
PCRE2SequenceNode >> startPredicate [

	| predicates |
	predicates := OrderedCollection new.
	children do: [ :child |
			| predicate |
			predicate := child startPredicate.
			predicate ifNil: [ ^ nil ].
			predicates add: predicate.
			child minimumLength > 0 ifTrue: [ ^ self startPredicateOf: predicates ] ].
	^ self startPredicateOf: predicates
]
