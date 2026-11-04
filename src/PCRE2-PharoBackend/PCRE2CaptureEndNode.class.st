"
Runtime continuation a capturing group pushes to record the extent of the group once its child has matched. Built while matching, never by the parser.
"
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

{ #category : 'matching' }
PCRE2CaptureEndNode >> executeIn: anEngine state: aState [

	aState captures at: index * 2 + 1 put: start.
	aState captures at: index * 2 + 2 put: aState position.
	aState lastCapture: index.
	^ aState
]

{ #category : 'accessing' }
PCRE2CaptureEndNode >> index [

	^ index
]

{ #category : 'accessing' }
PCRE2CaptureEndNode >> index: anInteger [

	index := anInteger
]

{ #category : 'accessing' }
PCRE2CaptureEndNode >> maximumLength [

	^ 0
]

{ #category : 'diagnostics' }
PCRE2CaptureEndNode >> runtimeStorageSize [

	^ self sizeInMemory
]

{ #category : 'accessing' }
PCRE2CaptureEndNode >> start: anInteger [

	start := anInteger
]

{ #category : 'optimization' }
PCRE2CaptureEndNode >> startPredicate [

	^ [ :character | false ]
]
