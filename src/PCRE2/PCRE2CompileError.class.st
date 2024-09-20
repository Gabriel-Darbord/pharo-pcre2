Class {
	#name : 'PCRE2CompileError',
	#superclass : 'PCRE2Error',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'signalling' }
PCRE2CompileError class >> signal: errorMessage in: pattern at: offset [

	self new signal: errorMessage in: pattern at: offset
]

{ #category : 'signalling' }
PCRE2CompileError >> signal: errorMessage in: pattern at: offset [
	"Insert the string '(*ERROR)' into the pattern to show where the error happened.
	The value returned in erroroffset is an indication of where in the pattern the error occurred.
	It is not necessarily the furthest point in the pattern that was read.
	For example, after the error 'lookbehind assertion is not fixed length', the error offset points to the start of the failing assertion.
	For an invalid UTF-8 or UTF-16 string, the offset is that of the first code unit of the failing character."

	| encoder rs |
	"The pattern is encoded in UTF-8, so it's a ByteArray that needs to be decoded"
	encoder := ZnUTF8Encoder default.
	rs := ReadStream on: pattern.
	self messageText: (String streamContents: [ :ws |
			 ws << errorMessage << ': '.
			 [ rs position >= offset ] whileFalse: [
				 ws nextPut: (encoder nextFromStream: rs) ].
			 ws nextPutAll: '(*ERROR)'.
			 [ rs atEnd ] whileFalse: [
				 ws nextPut: (encoder nextFromStream: rs) ] ]).
	self signal
]
