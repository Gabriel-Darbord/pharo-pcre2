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
PCRE2CaptureEndNode >> executeIn: anEngine state: aState [

	aState captures at: index * 2 + 1 put: start.
	aState captures at: index * 2 + 2 put: aState position.
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

{ #category : 'matching' }
PCRE2CaptureEndNode >> start: anInteger [

	start := anInteger
]
