"
Capturing group. Pushes the continuation that will record where the group ended, then its child.
"
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

{ #category : 'testing' }
PCRE2CaptureNode >> canAccept [

	^ child canAccept
]

{ #category : 'accessing' }
PCRE2CaptureNode >> child [

	^ child
]

{ #category : 'accessing' }
PCRE2CaptureNode >> child: aNode [

	child := aNode
]

{ #category : 'matching' }
PCRE2CaptureNode >> executeIn: anEngine state: aState [

	aState push: (PCRE2CaptureEndNode new
			 index: index;
			 start: aState position).
	aState push: child.
	^ aState
]

{ #category : 'optimization' }
PCRE2CaptureNode >> firstLiteral [

	^ child firstLiteral
]

{ #category : 'optimization' }
PCRE2CaptureNode >> firstLiteralPredicate [

	^ child firstLiteralPredicate
]

{ #category : 'accessing' }
PCRE2CaptureNode >> index [

	^ index
]

{ #category : 'accessing' }
PCRE2CaptureNode >> index: anInteger [

	index := anInteger
]

{ #category : 'optimization' }
PCRE2CaptureNode >> isAnchoredIn: analysis [

	^ child isAnchoredIn: (analysis withinGroup: index)
]

{ #category : 'optimization' }
PCRE2CaptureNode >> isStartLineIn: analysis [

	^ child isStartLineIn: (analysis withinGroup: index)
]

{ #category : 'accessing' }
PCRE2CaptureNode >> lengthBoundsUsing: groups names: names visited: visited [

	(visited includes: self) ifTrue: [ ^ { 0. nil } ].
	^ child lengthBoundsUsing: groups names: names visited: (visited copy
			   add: self;
			   yourself)
]

{ #category : 'accessing' }
PCRE2CaptureNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'accessing' }
PCRE2CaptureNode >> minimumLength [

	^ child minimumLength
]

{ #category : 'optimization' }
PCRE2CaptureNode >> requiredNode [

	^ child requiredNode
]

{ #category : 'optimization' }
PCRE2CaptureNode >> startPredicate [

	^ child startPredicate
]
