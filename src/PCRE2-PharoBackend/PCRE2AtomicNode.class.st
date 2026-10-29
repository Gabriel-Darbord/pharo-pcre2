Class {
	#name : 'PCRE2AtomicNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'private' }
PCRE2AtomicNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2AtomicNode >> child: aValue [

	child := aValue
]

{ #category : 'private' }
PCRE2AtomicNode >> executeIn: anEngine state: aState [

	| result tasks |
	tasks := aState tasks.
	result := anEngine matchNode: child state: aState.
	result ifNil: [ ^ nil ].
	result tasks: tasks.
	^ result
]

{ #category : 'matching' }
PCRE2AtomicNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'matching' }
PCRE2AtomicNode >> minimumLength [

	^ child minimumLength
]
