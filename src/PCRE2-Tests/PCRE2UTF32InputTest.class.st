"
Tests UTF-32 prepared inputs used by PCRE2's 32-bit code-unit API.
"
Class {
	#name : 'PCRE2UTF32InputTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2UTF32InputTest >> testBigEndianUTF32BytesAreNormalized [

	| input |
	input := #[ 0 0 0 99 0 0 0 97 0 0 0 102 0 0 0 233 ]
		         asPCRE2UTF32BigEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testDetectingUTF32BOMFallsBackToNativeEndian [

	| input subject |
	subject := 'café'.
	input := subject asPCRE2UTF32Input bytes
		         asPCRE2UTF32InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: subject
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testDetectingUTF32BOMStripsBigEndianBOM [

	| input |
	input := #[ 0 0 254 255 0 0 0 99 0 0 0 97 0 0 0 102 0 0 0 233 ]
		         asPCRE2UTF32InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testDetectingUTF32BOMStripsLittleEndianBOM [

	| input |
	input := #[ 255 254 0 0 99 0 0 0 97 0 0 0 102 0 0 0 233 0 0 0 ]
		         asPCRE2UTF32InputDetectingBOM.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testLittleEndianUTF32BytesAreNormalized [

	| input |
	input := #[ 99 0 0 0 97 0 0 0 102 0 0 0 233 0 0 0 ]
		         asPCRE2UTF32LittleEndianInput.

	self assert: input size equals: 4.
	self assert: (input readFrom: 1 to: 4) equals: 'café'
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testUTF32ByteInputRejectsInvalidSize [

	self
		should: [ PCRE2UTF32Input fromBytes: #[ 97 0 ] ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'divisible by four') ]
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testUTF32InputWithBOMAcceptsOnlyBOM [

	| input |
	input := #[ 255 254 0 0 ] asPCRE2UTF32InputWithBOM.

	self assert: input size equals: 0
]

{ #category : 'tests' }
PCRE2UTF32InputTest >> testUTF32InputWithBOMRejectsMissingBOM [

	self
		should: [ #[ 99 0 0 0 ] asPCRE2UTF32InputWithBOM ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
		self assert: (error messageText includesSubstring: 'BOM') ]
]
