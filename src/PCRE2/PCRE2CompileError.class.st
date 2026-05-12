Class {
	#name : 'PCRE2CompileError',
	#superclass : 'PCRE2Error',
	#instVars : [
		'errorMessage',
		'pattern',
		'offset'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'signalling' }
PCRE2CompileError class >> signal: errorMessage in: pattern at: offset [

	self new signal: errorMessage in: pattern at: offset
]

{ #category : 'accessing' }
PCRE2CompileError >> errorMessage [

	^ errorMessage
]

{ #category : 'accessing' }
PCRE2CompileError >> offset [

	^ offset
]

{ #category : 'accessing' }
PCRE2CompileError >> pattern [

	^ pattern
]

{ #category : 'signalling' }
PCRE2CompileError >> signal: anErrorMessage in: patternBytes at: anOffset [
	"Insert the string '(*ERROR)' into the pattern to show where PCRE2 reported the compile error. The offset is expressed in encoded code units, which are UTF-8 bytes in this binding."

	| encoder rs |
	errorMessage := anErrorMessage.
	offset := anOffset.
	encoder := ZnUTF8Encoder default.
	pattern := encoder decodeBytes: patternBytes.
	rs := ReadStream on: patternBytes.
	self messageText: (String streamContents: [ :ws |
			 ws << errorMessage << ': '.
			 [ rs position < offset ] whileTrue: [
				 ws nextPut: (encoder nextFromStream: rs) ].
			 ws nextPutAll: '(*ERROR)'.
			 [ rs atEnd ] whileFalse: [
				 ws nextPut: (encoder nextFromStream: rs) ] ]).
	self signal
]
