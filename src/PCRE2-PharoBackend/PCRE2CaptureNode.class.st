Class {
	#name : 'PCRE2CaptureNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'index',
		'child'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2CaptureNode >> canAccept [

	^ child canAccept
]

{ #category : 'private' }
PCRE2CaptureNode >> child [

	^ child
]

{ #category : 'private' }
PCRE2CaptureNode >> child: aValue [

	child := aValue
]

{ #category : 'matching' }
PCRE2CaptureNode >> executeIn: anEngine state: aState [

	aState push: (PCRE2CaptureEndNode new
			 index: index;
			 start: aState position).
	aState push: child.
	^ aState
]

{ #category : 'matching' }
PCRE2CaptureNode >> firstLiteral [

	^ child firstLiteral
]

{ #category : 'optimization' }
PCRE2CaptureNode >> firstLiteralPredicate [

	^ child firstLiteralPredicate
]

{ #category : 'private' }
PCRE2CaptureNode >> index [

	^ index
]

{ #category : 'private' }
PCRE2CaptureNode >> index: aValue [

	index := aValue
]

{ #category : 'matching' }
PCRE2CaptureNode >> lengthBoundsUsing: groups names: names visited: visited [

	(visited includes: self) ifTrue: [ ^ { 0. nil } ].
	^ child lengthBoundsUsing: groups names: names visited: (visited copy
			   add: self;
			   yourself)
]

{ #category : 'matching' }
PCRE2CaptureNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'matching' }
PCRE2CaptureNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'optimization' }
PCRE2CaptureNode >> requiredNode [

	^ child requiredNode
]

{ #category : 'matching' }
PCRE2CaptureNode >> startPredicate [

	^ child startPredicate
]
