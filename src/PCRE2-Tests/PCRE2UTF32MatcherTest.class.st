"
Tests PCRE2 matching through the 32-bit code-unit API.
"
Class {
	#name : 'PCRE2UTF32MatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2UTF32MatcherTest >> skipIfUTF32Unsupported [

	LibPCRE2 supports32BitCodeUnitWidth ifFalse: [ self skip ]
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompileErrorFromBytePatternDecodesPattern [

	| patternInput |
	self skipIfUTF32Unsupported.

	patternInput := #[ 40 0 0 0 97 0 0 0 ] asPCRE2UTF32LittleEndianInput.
	self should: [ PCRE2UTF32Compiler new compile: patternInput ] raise: PCRE2CompileError withExceptionDo: [ :error |
			self assert: error pattern equals: '(a'.
			self assert: error offset isInteger.
			self assert: (error messageText includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompilePatternFromBytesDetectingBOM [

	| patternInput regex |
	self skipIfUTF32Unsupported.

	patternInput := #[ 255 254 0 0 97 0 0 0 43 0 0 0 ] asPCRE2UTF32InputDetectingBOM.
	regex := PCRE2UTF32Compiler new compile: patternInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa').
	self deny: (regex matches: 'bbb')
]

{ #category : 'tests' }
PCRE2UTF32MatcherTest >> testCompilePatternFromLittleEndianBytes [

	| regex |
	self skipIfUTF32Unsupported.

	regex := PCRE2UTF32Compiler new compile: #[ 97 0 0 0 43 0 0 0 ] asPCRE2UTF32LittleEndianInput.

	self assert: regex pattern equals: 'a+'.
	self assert: (regex matches: 'aaa')
]
