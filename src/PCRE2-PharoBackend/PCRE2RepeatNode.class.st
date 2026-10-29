Class {
	#name : 'PCRE2RepeatNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child',
		'minimum',
		'maximum',
		'greedy'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2RepeatNode >> canAccept [

	^ child canAccept
]

{ #category : 'private' }
PCRE2RepeatNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2RepeatNode >> child: aValue [

	child := aValue
]

{ #category : 'matching' }
PCRE2RepeatNode >> executeIn: anEngine state: aState [

	(anEngine autoPossess: self state: aState) ifTrue: [ ^ anEngine possessRepeat: self state: aState ].
	aState push: (PCRE2RepeatFrame new
			 repeat: self;
			 count: 0;
			 previousPosition: nil).
	^ aState
]

{ #category : 'matching' }
PCRE2RepeatNode >> firstLiteral [

	^ minimum > 0 ifTrue: [ child firstLiteral ]
]

{ #category : 'private' }
PCRE2RepeatNode >> greedy [

	^ greedy
]

{ #category : 'private' }
PCRE2RepeatNode >> greedy: aValue [

	greedy := aValue
]

{ #category : 'matching' }
PCRE2RepeatNode >> lengthBoundsUsing: groups names: names visited: visited [

	| bounds |
	bounds := child lengthBoundsUsing: groups names: names visited: visited.
	^ {
		  (minimum * bounds first).
		  ((bounds second = 0 or: [ maximum = 0 ])
			   ifTrue: [ 0 ]
			   ifFalse: [ (bounds second isNil or: [ maximum isNil ]) ifFalse: [ maximum * bounds second ] ]) }
]

{ #category : 'private' }
PCRE2RepeatNode >> maximum [

	^ maximum
]

{ #category : 'private' }
PCRE2RepeatNode >> maximum: aValue [

	maximum := aValue
]

{ #category : 'matching' }
PCRE2RepeatNode >> maximumLength [

	| length |
	length := child maximumLength.
	length = 0 ifTrue: [ ^ 0 ].
	(maximum isNil or: [ length isNil ]) ifTrue: [ ^ nil ].
	^ maximum * length
]

{ #category : 'private' }
PCRE2RepeatNode >> minimum [

	^ minimum
]

{ #category : 'private' }
PCRE2RepeatNode >> minimum: aValue [

	minimum := aValue
]

{ #category : 'matching' }
PCRE2RepeatNode >> minimumLength [

	^ minimum * child minimumLength
]

{ #category : 'optimization' }
PCRE2RepeatNode >> requiredNode [

	^ minimum > 0 ifTrue: [ child requiredNode ]
]

{ #category : 'matching' }
PCRE2RepeatNode >> startPredicate [

	^ child startPredicate
]
