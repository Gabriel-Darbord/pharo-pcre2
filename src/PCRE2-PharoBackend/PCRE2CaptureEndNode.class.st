Class {
	#name : 'PCRE2CaptureEndNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'index',
		'start'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2CaptureEndNode >> acceptIn: engine state: state [

	self executeIn: engine state: state.
	^ false
]

{ #category : 'DFA matching' }
PCRE2CaptureEndNode >> dfaKey [

	^ #captureEnd
]

{ #category : 'matching' }
PCRE2CaptureEndNode >> executeIn: anEngine state: aState [

	aState captures at: index * 2 + 1 put: start.
	aState captures at: index * 2 + 2 put: aState position.
	aState lastCapture: index.
	^ aState
]

{ #category : 'private' }
PCRE2CaptureEndNode >> index [

	^ index
]

{ #category : 'private' }
PCRE2CaptureEndNode >> index: aValue [

	index := aValue
]

{ #category : 'DFA matching' }
PCRE2CaptureEndNode >> maximumLength [

	^ 0
]

{ #category : 'diagnostics' }
PCRE2CaptureEndNode >> runtimeStorageSize [

	^ self sizeInMemory
]

{ #category : 'matching' }
PCRE2CaptureEndNode >> start: anInteger [

	start := anInteger
]

{ #category : 'DFA matching' }
PCRE2CaptureEndNode >> startPredicate [

	^ [ :character | false ]
]
