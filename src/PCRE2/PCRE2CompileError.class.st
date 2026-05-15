"
I represent a pattern compilation failure reported by PCRE2.

I keep the decoded pattern, PCRE2's error message, and the encoded code-unit offset reported by the native compiler. My signalling helper inserts `(*ERROR)` into the decoded pattern so failures are easier to read.
"
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

{ #category : 'signalling' }
PCRE2CompileError class >> signal: errorMessage inInput: input at: offset [

	self new signal: errorMessage inInput: input at: offset
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

{ #category : 'signalling' }
PCRE2CompileError >> signal: anErrorMessage inInput: input at: codeUnitOffset [
	"Insert the string '(*ERROR)' into the decoded pattern at PCRE2's reported code-unit offset."

	| characterOffset head tail |
	errorMessage := anErrorMessage.
	offset := codeUnitOffset.
	pattern := input size = 0
		           ifTrue: [ '' ]
		           ifFalse: [ input readFrom: 1 to: input size ].
	characterOffset := input characterCountUpToByteOffset: codeUnitOffset.
	head := characterOffset = 0
		        ifTrue: [ '' ]
		        ifFalse: [ pattern copyFrom: 1 to: characterOffset ].
	tail := characterOffset >= pattern size
		        ifTrue: [ '' ]
		        ifFalse: [
		        pattern copyFrom: characterOffset + 1 to: pattern size ].
	self messageText: errorMessage , ': ' , head , '(*ERROR)' , tail.
	self signal
]
