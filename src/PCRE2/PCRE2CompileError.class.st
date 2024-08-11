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
	"Insert a <PCRE2_ERROR> tag into the pattern to show where the error happened.
	The value returned in erroroffset is an indication of where in the pattern the error occurred.
	It is not necessarily the furthest point in the pattern that was read.
	For example, after the error 'lookbehind assertion is not fixed length', the error offset points to the start of the failing assertion.
	For an invalid UTF-8 or UTF-16 string, the offset is that of the first code unit of the failing character."

	self messageText: (String streamContents: [ :s |
			 s << errorMessage << ': /'.
			 pattern isString
				 ifTrue: [ 1 to: offset do: [ :i | s nextPut: (pattern at: i) ] ]
				 ifFalse: [ "need to convert from ByteArray to utf8 string"
					 | stream |
					 stream := ReadStream on: pattern from: 1 to: offset.
					 1 to: offset do: [ :i |
					 s nextPut: (ZnUTF8Encoder default nextFromStream: stream) ] ].
			 s nextPutAll: '<PCRE2_ERROR>'.
			 pattern isString
				 ifTrue: [
				 offset + 1 to: pattern size do: [ :i |
				 s nextPut: (pattern at: i) ] ]
				 ifFalse: [
					 | stream |
					 stream := ReadStream
						           on: pattern
						           from: offset + 1
						           to: pattern size.
					 offset + 1 to: pattern size do: [ :i |
					 s nextPut: (ZnUTF8Encoder default nextFromStream: stream) ] ].
			 s nextPut: $/ ]).
	self signal
]
