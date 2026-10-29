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

{ #category : 'private' }
PCRE2CaptureNode >> index [

	^ index
]

{ #category : 'private' }
PCRE2CaptureNode >> index: aValue [

	index := aValue
]

{ #category : 'matching' }
PCRE2CaptureNode >> maximumLength [

	^ child maximumLength
]

{ #category : 'matching' }
PCRE2CaptureNode >> minimumLength [

	^ child minimumLength
]
