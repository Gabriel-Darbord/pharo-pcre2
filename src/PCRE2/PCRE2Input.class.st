"
Abstract superclass for prepared PCRE2 input.

Concrete subclasses bind the storage and offset semantics for PCRE2's 8-bit, 16-bit, and 32-bit APIs. This class keeps the shared prepared-input protocol used by matchers and match results.
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
PCRE2Input >> characterCountUpToByteOffset: codeUnitOffset [

	^ self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based input offsets to a 1-based Pharo character range."

	^ (self characterCountUpToByteOffset: zeroBasedStartOffset) + 1 to:
	  (self characterCountUpToByteOffset: exclusiveEndOffset)
]

{ #category : 'decoding' }
PCRE2Input >> decodeBytes: aByteCollection [

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

	^ self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2Input >> readFrom: start to: end [

	^ self subclassResponsibility
]

{ #category : 'matching' }
PCRE2Input >> recordOn: aPCRE2Match [

	aPCRE2Match input: self
]

{ #category : 'accessing' }
PCRE2Input >> size [

	^ self subclassResponsibility
]
