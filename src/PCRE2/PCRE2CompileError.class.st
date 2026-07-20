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
PCRE2CompileError class >> signal: errorMessage in: input at: codeUnitOffset [
	"Signal a compile error for prepared PCRE2 input at a zero-based code-unit offset."

	self new signal: errorMessage in: input at: codeUnitOffset
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
PCRE2CompileError >> signal: anErrorMessage in: input at: codeUnitOffset [
	"Insert '(*ERROR)' into the decoded pattern at the character position corresponding to PCRE2's reported code-unit offset."

	| characterOffset head tail |
	errorMessage := anErrorMessage.
	offset := codeUnitOffset.
	pattern := input size = 0
		           ifTrue: [ '' ]
		           ifFalse: [ input readFrom: 1 to: input size ].
	characterOffset := input characterCountUpToCodeUnitOffset: codeUnitOffset.
	head := characterOffset = 0
		        ifTrue: [ '' ]
		        ifFalse: [ pattern copyFrom: 1 to: characterOffset ].
	tail := characterOffset >= pattern size
		        ifTrue: [ '' ]
		        ifFalse: [ pattern copyFrom: characterOffset + 1 to: pattern size ].
	self messageText: errorMessage , ': ' , head , '(*ERROR)' , tail.
	self signal
]
