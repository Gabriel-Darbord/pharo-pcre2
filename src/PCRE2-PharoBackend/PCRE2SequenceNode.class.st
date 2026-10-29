Class {
	#name : 'PCRE2SequenceNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'children'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2SequenceNode >> canAccept [

	^ children anySatisfy: #canAccept
]

{ #category : 'private' }
PCRE2SequenceNode >> children [

	^ children
]

{ #category : 'private' }
PCRE2SequenceNode >> children: aValue [

	children := aValue
]

{ #category : 'private' }
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

{ #category : 'matching' }
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

{ #category : 'matching' }
PCRE2SequenceNode >> maximumLength [

	| sum |
	sum := 0.
	children do: [ :node | node maximumLength ifNil: [ ^ nil ] ifNotNil: [ :length | sum := sum + length ] ].
	^ sum
]

{ #category : 'optimization' }
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

{ #category : 'matching' }
PCRE2SequenceNode >> startPredicate [

	| predicates |
	predicates := OrderedCollection new.
	children do: [ :child |
			| predicate |
			predicate := child startPredicate.
			predicate ifNil: [ ^ nil ].
			predicates add: predicate.
			child minimumLength > 0 ifTrue: [ ^ [ :character | predicates anySatisfy: [ :test | test value: character ] ] ] ].
	^ [ :character | predicates anySatisfy: [ :test | test value: character ] ]
]
