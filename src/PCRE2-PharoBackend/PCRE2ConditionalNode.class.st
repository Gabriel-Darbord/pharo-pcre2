Class {
	#name : 'PCRE2ConditionalNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'condition',
		'thenBranch',
		'elseBranch',
		'definition',
		'dfaUnsupported'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2ConditionalNode >> canAccept [

	^ thenBranch canAccept or: [ elseBranch canAccept ]
]

{ #category : 'matching' }
PCRE2ConditionalNode >> condition: predicate then: yesNode else: noNode [

	condition := predicate.
	thenBranch := yesNode.
	elseBranch := noNode
]

{ #category : 'matching' }
PCRE2ConditionalNode >> definition: boolean [

	definition := boolean
]

{ #category : 'DFA matching' }
PCRE2ConditionalNode >> dfaError [

	^ dfaUnsupported = true
		  ifTrue: [ -40 ]
		  ifFalse: [ 0 ]
]

{ #category : 'DFA matching' }
PCRE2ConditionalNode >> dfaUnsupported: boolean [

	dfaUnsupported := boolean
]

{ #category : 'matching' }
PCRE2ConditionalNode >> executeIn: engine state: state [

	state push: ((condition value: engine value: state)
			 ifTrue: [ thenBranch ]
			 ifFalse: [ elseBranch ]).
	^ state
]

{ #category : 'matching' }
PCRE2ConditionalNode >> lengthBoundsUsing: groups names: names visited: visited [

	| yes no |
	no := elseBranch lengthBoundsUsing: groups names: names visited: visited.
	definition = true ifTrue: [ ^ no ].
	yes := thenBranch lengthBoundsUsing: groups names: names visited: visited.
	^ {
		  (yes first min: no first).
		  ((yes second isNil or: [ no second isNil ]) ifFalse: [ yes second max: no second ]) }
]

{ #category : 'matching' }
PCRE2ConditionalNode >> maximumLength [

	| yes no |
	definition = true ifTrue: [ ^ elseBranch maximumLength ].
	yes := thenBranch maximumLength.
	no := elseBranch maximumLength.
	(yes isNil or: [ no isNil ]) ifTrue: [ ^ nil ].
	^ yes max: no
]

{ #category : 'matching' }
PCRE2ConditionalNode >> minimumLength [

	^ thenBranch minimumLength min: elseBranch minimumLength
]
