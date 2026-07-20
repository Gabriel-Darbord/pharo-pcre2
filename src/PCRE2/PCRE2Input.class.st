"
Abstract superclass for prepared PCRE2 input.

Concrete subclasses bind the storage and offset semantics for PCRE2's 8-bit, 16-bit, and 32-bit APIs. Matchers and match results use this shared protocol to access encoded storage, translate PCRE2 code-unit offsets to Pharo character ranges, decode captured text, and advance after empty matches.

Unless a method says otherwise, offsets in this protocol are PCRE2 code-unit offsets. Those are bytes for PCRE2-8, 16-bit UTF-16 units for PCRE2-16, and 32-bit code units for PCRE2-32.
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

	^ self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> characterCountUpToCodeUnitOffset: codeUnitOffset fromCodeUnitOffset: knownCodeUnitOffset characterCount: knownCharacterCount [
	"Answer the Pharo character count at the requested code-unit offset. knownCodeUnitOffset/knownCharacterCount describe an earlier point in the same input; subclasses may use them to avoid recounting a prefix."

	^ self characterCountUpToCodeUnitOffset: codeUnitOffset
]

{ #category : 'decoding' }
PCRE2Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based code-unit interval to a 1-based Pharo character range. The end offset is exclusive, matching PCRE2 match offsets."

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
	"Decode encoded input storage into a Pharo string according to the receiver's PCRE2 code-unit width."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Input >> decoder [

	^ nil
]

{ #category : 'decoding' }
PCRE2Input >> nextFromStream: aStream [

	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Input >> nextMatchStartOffsetAfter: zeroBasedOffset [
	"Answer the next zero-based PCRE2 code-unit offset after one Pharo character. Used to advance safely after an empty match."

	^ self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> readFrom: start to: end [
	"Answer decoded text between the inclusive 1-based PCRE2 code-unit indexes."

	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Input >> recordOn: aPCRE2Match [

	aPCRE2Match input: self
]

{ #category : 'accessing' }
PCRE2Input >> size [
	"Answer the input size in PCRE2 code units."

	^ self subclassResponsibility
]
