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

{ #category : 'private' }
PCRE2RepeatNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2RepeatNode >> child: aValue [

	child := aValue
]

{ #category : 'private' }
PCRE2RepeatNode >> executeIn: anEngine state: aState [

	aState push: (PCRE2RepeatFrame new
			 repeat: self;
			 count: 0;
			 previousPosition: nil).
	^ aState
]

{ #category : 'private' }
PCRE2RepeatNode >> greedy [

	^ greedy
]

{ #category : 'private' }
PCRE2RepeatNode >> greedy: aValue [

	greedy := aValue
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
