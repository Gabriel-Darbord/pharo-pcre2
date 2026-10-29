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

{ #category : 'private' }
PCRE2RepeatFrame >> count [

	^ count
]

{ #category : 'private' }
PCRE2RepeatFrame >> count: aValue [

	count := aValue
]

{ #category : 'DFA matching' }
PCRE2RepeatFrame >> dfaKey [

	^ {
		  repeat.
		  (repeat maximum ifNil: [ count min: repeat minimum ] ifNotNil: [ count ]).
		  previousPosition }
]

{ #category : 'private' }
PCRE2RepeatFrame >> executeIn: anEngine state: aState [

	| canStop canRepeat next |
	canStop := count >= repeat minimum.
	canRepeat := (repeat maximum isNil or: [ count < repeat maximum ]) and: [
			             previousPosition ~= aState position or: [
				             (previousCaptures isNotNil and: [ previousCaptures ~= aState captures ]) or: [ canStop not ] ] ].
	canRepeat ifFalse: [
			^ canStop
				  ifTrue: [ aState ]
				  ifFalse: [ nil ] ].
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

{ #category : 'private' }
PCRE2RepeatFrame >> previousCaptures: captures [

	previousCaptures := captures
]

{ #category : 'private' }
PCRE2RepeatFrame >> previousPosition [

	^ previousPosition
]

{ #category : 'private' }
PCRE2RepeatFrame >> previousPosition: aValue [

	previousPosition := aValue
]

{ #category : 'private' }
PCRE2RepeatFrame >> repeat [

	^ repeat
]

{ #category : 'private' }
PCRE2RepeatFrame >> repeat: aValue [

	repeat := aValue
]

{ #category : 'diagnostics' }
PCRE2RepeatFrame >> runtimeStorageSize [

	^ self sizeInMemory
]
