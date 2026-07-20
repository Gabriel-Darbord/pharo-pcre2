"
Covers PCRE2's native pattern conversion helpers for glob and POSIX patterns.
"
Class {
	#name : 'PCRE2PatternConversionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2PatternConversionTest >> skipUnlessPatternConversionSupported [

	LibPCRE2 supportsPatternConversion ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (LibPCRE2UTF8 convertGlob: '*.st') asPerlCompatibleRegex.

	self assert: (regex matches: 'Foo.st').
	self deny: (regex matches: 'Foo.md').
	self deny: (regex matches: 'src/Foo.st')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobCanUseCustomEscape [

	| context regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].
	context := LibPCRE2UTF8 newConvertContext.
	context globEscape: $!.

	regex := (LibPCRE2UTF8 convertGlob: 'file!*.st' context: context) asPerlCompatibleRegex.

	self assert: (regex matches: 'file*.st').
	self deny: (regex matches: 'fileABC.st')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobPreservesUTF8Text [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (LibPCRE2UTF8 convertGlob: '*é') asPerlCompatibleRegex.

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobSignalsConversionErrors [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	self should: [ LibPCRE2UTF8 convertGlob: '[abc' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertPOSIXBasicCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (LibPCRE2UTF8 convertPOSIXBasic: 'a\{2\}') asPerlCompatibleRegex.

	self assert: (regex matches: 'aa').
	self deny: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertPOSIXExtendedCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (LibPCRE2UTF8 convertPOSIXExtended: 'a(b|c)+') asPerlCompatibleRegex.

	self assert: (regex matches: 'abcb').
	self deny: (regex matches: 'ad')
]
