"
Conditional group: runs the then or the else branch according to a condition asking whether a group is set, whether a subroutine is recursing, or how a lookaround turned out. A DEFINE group matches nothing and only holds subroutines. The lookaround a condition runs is kept beside it, because the start optimizations must look at it first.
"
Class {
	#name : 'PCRE2ConditionalNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'condition',
		'thenBranch',
		'elseBranch',
		'definition',
		'dfaUnsupported',
		'prefix',
		'assertion',
		'hasElse',
		'neverRuns',
		'byteCondition'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2ConditionalNode >> assertion: aNode [

	assertion := aNode
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> byteCondition [
	"What a written matcher can ask of this condition, or nil for a recursion, a name shared by several groups or a lookaround."

	^ byteCondition
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> byteCondition: anArray [

	byteCondition := anArray
]

{ #category : 'testing' }
PCRE2ConditionalNode >> canAccept [

	^ thenBranch canAccept or: [ elseBranch canAccept ]
]

{ #category : 'matching' }
PCRE2ConditionalNode >> condition: predicate then: yesNode else: noNode [

	condition := predicate.
	thenBranch := yesNode.
	elseBranch := noNode
]

{ #category : 'optimization' }
PCRE2ConditionalNode >> conditionalStart [
	"What runs first when this conditional is entered: the lookaround the condition asks, or else the branch it guards."

	^ assertion ifNil: [ thenBranch ]
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> definition: boolean [

	definition := boolean
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> dfaUnsupported: boolean [

	dfaUnsupported := boolean
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> elseBranch [

	^ elseBranch
]

{ #category : 'matching' }
PCRE2ConditionalNode >> executeIn: engine state: state [

	(prefix ifNil: [ #(  ) ]) do: [ :node | (node executeIn: engine state: state) ifNil: [ ^ nil ] ].
	state push: ((condition value: engine value: state)
			 ifTrue: [ thenBranch ]
			 ifFalse: [ elseBranch ]).
	^ state
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> hasElse: aBoolean [

	hasElse := aBoolean
]

{ #category : 'optimization' }
PCRE2ConditionalNode >> isAnchoredIn: analysis [
	"Both halves have to say the same thing. A conditional with only one branch can match nothing at all, and so says nothing about where a match begins."

	^ hasElse = true and: [ (self conditionalStart isAnchoredIn: analysis) and: [ elseBranch isAnchoredIn: analysis ] ]
]

{ #category : 'optimization' }
PCRE2ConditionalNode >> isSignificantForStart [
	"PCRE2 passes over a conditional that can never run: a DEFINE group or a failed version test, a single branch under a condition known to be false."

	^ neverRuns ~= true
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> lengthBoundsUsing: groups names: names visited: visited [

	| yes no |
	no := elseBranch lengthBoundsUsing: groups names: names visited: visited.
	definition = true ifTrue: [ ^ no ].
	yes := thenBranch lengthBoundsUsing: groups names: names visited: visited.
	^ {
		  (yes first min: no first).
		  ((yes second isNil or: [ no second isNil ]) ifFalse: [ yes second max: no second ]) }
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> maximumLength [

	| yes no |
	definition = true ifTrue: [ ^ elseBranch maximumLength ].
	yes := thenBranch maximumLength.
	no := elseBranch maximumLength.
	(yes isNil or: [ no isNil ]) ifTrue: [ ^ nil ].
	^ yes max: no
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> minimumLength [

	^ thenBranch minimumLength min: elseBranch minimumLength
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> neverRuns: aBoolean [

	neverRuns := aBoolean
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> prefix: nodes [

	prefix := nodes
]

{ #category : 'accessing' }
PCRE2ConditionalNode >> thenBranch [

	^ thenBranch
]

{ #category : 'generating' }
PCRE2ConditionalNode >> writeInto: aGenerator at: position then: aBlock [

	^ aGenerator writeConditional: self at: position then: aBlock
]
