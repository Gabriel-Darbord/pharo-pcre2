"
Repetition with a minimum, a maximum and a greediness. Greedy and lazy forms differ only in which continuation runs now and which is enqueued; a possessive repetition runs its child in a nested match instead.
"
Class {
	#name : 'PCRE2RepeatNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'child',
		'minimum',
		'maximum',
		'greedy',
		'characterRepeat'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2RepeatNode >> canAccept [

	^ child canAccept
]

{ #category : 'accessing' }
PCRE2RepeatNode >> child [

	^ child
]

{ #category : 'accessing' }
PCRE2RepeatNode >> child: aNode [

	child := aNode
]

{ #category : 'matching' }
PCRE2RepeatNode >> executeIn: anEngine state: aState [

	(anEngine autoPossess: self state: aState) ifTrue: [ ^ anEngine possessRepeat: self state: aState ].
	(self isCharacterRepeat and: [ anEngine scansRepeats ]) ifTrue: [ ^ anEngine scanRepeat: self state: aState ].
	aState push: (PCRE2RepeatFrame new
			 repeat: self;
			 count: 0;
			 previousPosition: nil).
	^ aState
]

{ #category : 'optimization' }
PCRE2RepeatNode >> firstLiteral [

	^ minimum > 0 ifTrue: [ child firstLiteral ]
]

{ #category : 'optimization' }
PCRE2RepeatNode >> firstLiteralPredicate [

	^ minimum > 0 ifTrue: [ child firstLiteralPredicate ]
]

{ #category : 'accessing' }
PCRE2RepeatNode >> greedy [

	^ greedy
]

{ #category : 'accessing' }
PCRE2RepeatNode >> greedy: aBoolean [

	greedy := aBoolean
]

{ #category : 'optimization' }
PCRE2RepeatNode >> isAnchoredIn: analysis [
	"A branch opening with .* where the dot matches everything has already tried every position the pattern could start at, so there is no point starting it again further along. Any other repetition says where a match begins only when it has to run at least once."

	(self isLeadingDotStar and: [ child acceptsEveryCharacter ]) ifTrue: [ ^ analysis allowsLeadingDotStar ].
	^ minimum > 0 and: [ child isAnchoredIn: analysis ]
]

{ #category : 'testing' }
PCRE2RepeatNode >> isCharacterRepeat [
	"Whether this is a greedy repetition of one character, which the engine counts off in one step instead of taking a choice for every turn. A lazy one gains nothing: it has to offer every length to the rest of the pattern anyway."

	^ characterRepeat ifNil: [ characterRepeat := greedy and: [ child isSingleCharacter ] ]
]

{ #category : 'optimization' }
PCRE2RepeatNode >> isLeadingDotStar [
	"Whether this is a dot repeated any number of times, which is the one repetition PCRE2 reads as saying where a match can begin."

	^ minimum = 0 and: [ maximum isNil ]
]

{ #category : 'optimization' }
PCRE2RepeatNode >> isSignificantForStart [
	"A repetition that cannot run even once leaves nothing for the start optimizations to look at."

	^ maximum ~= 0
]

{ #category : 'optimization' }
PCRE2RepeatNode >> isStartLineIn: analysis [
	"A branch opening with .* where the dot stops at line ends can only begin at the start of the subject or just after a line terminator. Any other repetition says where a match begins only when it has to run at least once."

	(self isLeadingDotStar and: [ child acceptsEveryCharacterButLineEnds ]) ifTrue: [ ^ analysis allowsLeadingDotStar ].
	^ minimum > 0 and: [ child isStartLineIn: analysis ]
]

{ #category : 'accessing' }
PCRE2RepeatNode >> lengthBoundsUsing: groups names: names visited: visited [

	| bounds |
	bounds := child lengthBoundsUsing: groups names: names visited: visited.
	^ {
		  (minimum * bounds first).
		  ((bounds second = 0 or: [ maximum = 0 ])
			   ifTrue: [ 0 ]
			   ifFalse: [ (bounds second isNil or: [ maximum isNil ]) ifFalse: [ maximum * bounds second ] ]) }
]

{ #category : 'accessing' }
PCRE2RepeatNode >> maximum [

	^ maximum
]

{ #category : 'accessing' }
PCRE2RepeatNode >> maximum: anInteger [

	maximum := anInteger
]

{ #category : 'accessing' }
PCRE2RepeatNode >> maximumLength [

	| length |
	length := child maximumLength.
	length = 0 ifTrue: [ ^ 0 ].
	(maximum isNil or: [ length isNil ]) ifTrue: [ ^ nil ].
	^ maximum * length
]

{ #category : 'accessing' }
PCRE2RepeatNode >> minimum [

	^ minimum
]

{ #category : 'accessing' }
PCRE2RepeatNode >> minimum: anInteger [

	minimum := anInteger
]

{ #category : 'accessing' }
PCRE2RepeatNode >> minimumLength [

	^ minimum * child minimumLength
]

{ #category : 'optimization' }
PCRE2RepeatNode >> requiredNode [

	^ minimum > 0 ifTrue: [ child requiredNode ]
]

{ #category : 'optimization' }
PCRE2RepeatNode >> startPredicate [

	^ child startPredicate
]

{ #category : 'generating' }
PCRE2RepeatNode >> writeInto: aGenerator at: position then: aBlock [

	^ aGenerator writeRepeat: self at: position then: aBlock
]

{ #category : 'generating' }
PCRE2RepeatNode >> writePossessivelyInto: aGenerator at: position then: aBlock [

	^ aGenerator writePossessiveRepeat: self at: position then: aBlock
]
