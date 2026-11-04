"
I am a display row for one capture of a trace step: its number, character range and subject text.
"
Class {
	#name : 'PCRE2TraceCaptureRow',
	#superclass : 'Object',
	#instVars : [
		'index',
		'range',
		'text'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2TraceCaptureRow class >> index: captureIndex range: anIntervalOrNil text: aString [

	^ self new initializeIndex: captureIndex range: anIntervalOrNil text: aString
]

{ #category : 'display' }
PCRE2TraceCaptureRow >> displayIndex [

	index = 0 ifTrue: [ ^ 'Full' ].
	^ index asString
]

{ #category : 'display' }
PCRE2TraceCaptureRow >> displayRange [

	range ifNil: [ ^ 'unset' ].
	range isEmpty ifTrue: [ ^ range first asString , ' (empty)' ].
	^ String streamContents: [ :stream | stream << range first asString << '-' << range last asString ]
]

{ #category : 'accessing' }
PCRE2TraceCaptureRow >> index [

	^ index
]

{ #category : 'initialization' }
PCRE2TraceCaptureRow >> initializeIndex: captureIndex range: anIntervalOrNil text: aString [

	index := captureIndex.
	range := anIntervalOrNil.
	text := aString ifNil: [ '' ]
]

{ #category : 'accessing' }
PCRE2TraceCaptureRow >> range [

	^ range
]

{ #category : 'accessing' }
PCRE2TraceCaptureRow >> text [

	^ text
]
