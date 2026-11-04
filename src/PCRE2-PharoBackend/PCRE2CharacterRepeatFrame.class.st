"
Runtime continuation for a repetition of single characters the engine counted off in one step. It holds the current count, and running it gives one character back. Built while matching, never by the parser.
"
Class {
	#name : 'PCRE2CharacterRepeatFrame',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'repeat',
		'count'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'accessing' }
PCRE2CharacterRepeatFrame >> count: anInteger [

	count := anInteger
]

{ #category : 'matching' }
PCRE2CharacterRepeatFrame >> executeIn: anEngine state: aState [
	"Give one character back and let the rest of the pattern run from there, keeping the shorter runs for later."

	| remaining next |
	aState position: (anEngine subject previousOffsetFrom: aState position).
	remaining := count - 1.
	remaining > repeat minimum ifTrue: [
			next := aState copy.
			next push: (self class new
					 repeat: repeat;
					 count: remaining).
			anEngine enqueue: next ].
	^ aState
]

{ #category : 'accessing' }
PCRE2CharacterRepeatFrame >> repeat: aRepeatNode [

	repeat := aRepeatNode
]

{ #category : 'diagnostics' }
PCRE2CharacterRepeatFrame >> runtimeStorageSize [

	^ self sizeInMemory
]
