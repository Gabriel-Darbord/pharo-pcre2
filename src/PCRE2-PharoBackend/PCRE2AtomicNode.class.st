Class {
	#name : 'PCRE2AtomicNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2AtomicNode >> canAccept [

	^ child canAccept
]

{ #category : 'private' }
PCRE2AtomicNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2AtomicNode >> child: aValue [

	child := aValue
]

{ #category : 'matching' }
PCRE2AtomicNode >> executeIn: engine state: state [

	| result |
	result := engine matchNode: child state: state propagate: #atomic.
	result ifNil: [ ^ nil ].
	result
		tasks: state tasks;
		alternations: state alternations;
		marks: state marks.
	result accepted ifTrue: [
			result accepted: false.
			^ engine accept: result ].
	^ result
]

{ #category : 'matching' }
PCRE2AtomicNode >> firstLiteral [

	^ child firstLiteral
]

{ #category : 'optimization' }
PCRE2AtomicNode >> firstLiteralPredicate [

	^ child firstLiteralPredicate
]

{ #category : 'matching' }
PCRE2AtomicNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ child lengthBoundsUsing: groups names: names visited: visited
]

{ #category : 'matching' }
PCRE2AtomicNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'matching' }
PCRE2AtomicNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'optimization' }
PCRE2AtomicNode >> requiredNode [

	^ child requiredNode
]

{ #category : 'matching' }
PCRE2AtomicNode >> startPredicate [

	^ child startPredicate
]
