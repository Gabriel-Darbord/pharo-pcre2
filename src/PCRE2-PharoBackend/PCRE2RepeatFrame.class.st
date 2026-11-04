"
Runtime continuation for one turn of a repetition. It carries the turn count and the position and captures of the previous turn, which is how the engine stops a repetition whose body matches nothing. Built while matching, never by the parser.
"
Class {
	#name : 'PCRE2RepeatFrame',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'repeat',
		'count',
		'previousPosition',
		'previousCaptures'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2RepeatFrame >> count [

	^ count
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> count: anInteger [

	count := anInteger
]

{ #category : 'matching' }
PCRE2RepeatFrame >> executeIn: anEngine state: aState [

	| canStop canRepeat next |
	canStop := count >= repeat minimum.
	canRepeat := (repeat maximum isNil or: [ count < repeat maximum ]) and: [
			             previousPosition ~= aState position or: [
				             (previousCaptures isNotNil and: [ previousCaptures ~= aState captures ]) or: [ canStop not ] ] ].
	canRepeat ifFalse: [ ^ canStop ifTrue: [ aState ] ].
	next := aState copy.
	next push: (self class new
			 repeat: repeat;
			 count: count + 1;
			 previousPosition: aState position;
			 previousCaptures: (repeat child maximumLength = 0 ifTrue: [ aState captures copy ])).
	next push: repeat child.
	canStop ifFalse: [ ^ next ].
	repeat greedy
		ifTrue: [
				anEngine enqueue: aState.
				^ next ]
		ifFalse: [
				anEngine enqueue: next.
				^ aState ]
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> previousCaptures: captures [

	previousCaptures := captures
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> previousPosition [

	^ previousPosition
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> previousPosition: anInteger [

	previousPosition := anInteger
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> repeat [

	^ repeat
]

{ #category : 'accessing' }
PCRE2RepeatFrame >> repeat: aRepeatNode [

	repeat := aRepeatNode
]

{ #category : 'diagnostics' }
PCRE2RepeatFrame >> runtimeStorageSize [

	^ self sizeInMemory
]
