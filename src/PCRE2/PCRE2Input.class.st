"
Abstract superclass for prepared PCRE2 input. Subclasses hold the encoded storage for the 8-, 16- and 32-bit APIs, translate PCRE2 code-unit offsets to Pharo character ranges, and decode captured text.

Unless a method says otherwise, offsets are PCRE2 code-unit offsets: bytes for PCRE2-8, 16-bit units for PCRE2-16, and 32-bit units for PCRE2-32.
"
Class {
	#name : 'PCRE2Input',
	#superclass : 'Object',
	#instVars : [
		'bytes'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2Input class >> isAbstract [

	^ self == PCRE2Input
]

{ #category : 'accessing' }
PCRE2Input >> bytes [

	^ bytes
]

{ #category : 'initialization' }
PCRE2Input >> bytes: bytesObject [

	bytes := bytesObject
]

{ #category : 'decoding' }
PCRE2Input >> characterCountUpToCodeUnitOffset: codeUnitOffset [
	"Answer how many Pharo characters appear before the zero-based PCRE2 code-unit offset."

	self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Answer the Pharo character count at codeUnitOffset. knownCodeUnitOffset and knownCharacterCount describe an earlier point that subclasses may count from."

	^ self characterCountUpToCodeUnitOffset: codeUnitOffset
]

{ #category : 'decoding' }
PCRE2Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate a zero-based code-unit interval, end exclusive, to a 1-based Pharo character range."

	| exclusiveEndCharacterCount startCharacterCount |
	startCharacterCount := self characterCountUpToCodeUnitOffset: zeroBasedStartOffset.
	exclusiveEndCharacterCount := self
		                              characterCountUpToCodeUnitOffset: exclusiveEndOffset
		                              fromCodeUnitOffset: zeroBasedStartOffset
		                              characterCount: startCharacterCount.
	^ startCharacterCount + 1 to: exclusiveEndCharacterCount
]

{ #category : 'decoding' }
PCRE2Input >> decodeBytes: aByteCollection [
	"Decode encoded storage into a Pharo string."

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Input >> decoder [

	^ nil
]

{ #category : 'displaying' }
PCRE2Input >> displayFrom: start to: end [
	"Use escapes when a raw pattern is not representable as Unicode text."

	| decoded width |
	start > end ifTrue: [ ^ '' ].
	decoded := [ self readFrom: start to: end ]
		           on: ZnCharacterEncodingError , PrimitiveFailed
		           do: [ :error | nil ].
	(decoded isNotNil and: [
			 decoded allSatisfy: [ :character |
				 character asInteger <= 16r10FFFF and: [ (character asInteger between: 16rD800 and: 16rDFFF) not ] ] ]) ifTrue: [
		^ decoded asString ].
	width := bytes size // self size.
	^ String streamContents: [ :stream |
			  start to: end do: [ :index |
					  | unit |
					  unit := width = 1
						          ifTrue: [ bytes at: index ]
						          ifFalse: [
								          width = 2
									          ifTrue: [ bytes uint16AtOffset: index - 1 * 2 ]
									          ifFalse: [ bytes uint32AtOffset: index - 1 * 4 ] ].
					  stream
						  nextPutAll: '\x{';
						  nextPutAll: (unit asInteger printStringBase: 16);
						  nextPut: $} ] ]
]

{ #category : 'decoding' }
PCRE2Input >> nextFromStream: aStream [

	self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based PCRE2 code-unit offset after one Pharo character. Used to advance safely after an empty match."

	self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> readFrom: start to: end [
	"Answer decoded text between the inclusive 1-based PCRE2 code-unit indexes."

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Input >> size [
	"Answer the input size in PCRE2 code units."

	self subclassResponsibility
]
