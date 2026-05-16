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

	LibPCRE2UTF8 supportsPatternConversion ifFalse: [ ^ true ].
	^ false
]

{ #category : 'private' }
PCRE2PatternConversionTest >> skipUnlessUTF16PatternConversionSupported [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ true ].
	LibPCRE2UTF8 supports16BitCodeUnitWidth ifFalse: [ ^ true ].
	^ false
]

{ #category : 'private' }
PCRE2PatternConversionTest >> skipUnlessUTF32PatternConversionSupported [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ true ].
	LibPCRE2UTF8 supports32BitCodeUnitWidth ifFalse: [ ^ true ].
	^ false
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertContextsAreWidthSpecific [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	self
		assert: LibPCRE2UTF8 newConvertContext class
		equals: PCRE2UTF8ConvertContext.
	self skipUnlessUTF16PatternConversionSupported ifFalse: [
		self
			assert: LibPCRE2UTF16 newConvertContext class
			equals: PCRE2UTF16ConvertContext ].
	self skipUnlessUTF32PatternConversionSupported ifFalse: [
		self
			assert: LibPCRE2UTF32 newConvertContext class
			equals: PCRE2UTF32ConvertContext ]
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (PCRE2 convertGlob: '*.st') asPerlCompatibleRegex.

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

	regex := (PCRE2 convertGlob: 'file!*.st' context: context)
		         asPerlCompatibleRegex.

	self assert: (regex matches: 'file*.st').
	self deny: (regex matches: 'fileABC.st')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobPreservesUTF8Text [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (PCRE2 convertGlob: '*é') asPerlCompatibleRegex.

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobSignalsConversionErrors [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	self should: [ PCRE2 convertGlob: '[abc' ] raise: PCRE2CompileError
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertGlobUsesDefaultLibraryFacade [

	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	self
		assert: (PCRE2 convertGlob: '*.st')
		equals: (PCRE2 defaultLibraryClass convertGlob: '*.st')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertPOSIXBasicCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (PCRE2 convertPOSIXBasic: 'a\{2\}') asPerlCompatibleRegex.

	self assert: (regex matches: 'aa').
	self deny: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testConvertPOSIXExtendedCanCompileAndMatch [

	| regex |
	self skipUnlessPatternConversionSupported ifTrue: [ ^ self ].

	regex := (PCRE2 convertPOSIXExtended: 'a(b|c)+')
		         asPerlCompatibleRegex.

	self assert: (regex matches: 'abcb').
	self deny: (regex matches: 'ad')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF16LibraryCanConvertGlobAndMatch [

	| regex |
	self skipUnlessUTF16PatternConversionSupported ifTrue: [ ^ self ].

	regex := PCRE2UTF16Compiler new compile:
		         (LibPCRE2UTF16 convertGlob: '*é').

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF16LibraryCanConvertPreparedGlobBytes [

	| patternBytes regex |
	self skipUnlessUTF16PatternConversionSupported ifTrue: [ ^ self ].
	patternBytes := '*é' asPCRE2UTF16Input bytes.

	regex := PCRE2UTF16Compiler new compile:
		         (LibPCRE2UTF16 convertGlob: patternBytes).

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF16LibraryCanUseConvertContext [

	| context regex |
	self skipUnlessUTF16PatternConversionSupported ifTrue: [ ^ self ].
	context := LibPCRE2UTF16 newConvertContext.
	context globEscape: $!.

	regex := PCRE2UTF16Compiler new compile:
		         (LibPCRE2UTF16 convertGlob: 'file!*.st' context: context).

	self assert: (regex matches: 'file*.st').
	self deny: (regex matches: 'fileABC.st')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF32LibraryCanConvertGlobAndMatch [

	| regex |
	self skipUnlessUTF32PatternConversionSupported ifTrue: [ ^ self ].

	regex := PCRE2UTF32Compiler new compile:
		         (LibPCRE2UTF32 convertGlob: '*é').

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF32LibraryCanConvertPreparedGlobBytes [

	| patternBytes regex |
	self skipUnlessUTF32PatternConversionSupported ifTrue: [ ^ self ].
	patternBytes := '*é' asPCRE2UTF32Input bytes.

	regex := PCRE2UTF32Compiler new compile:
		         (LibPCRE2UTF32 convertGlob: patternBytes).

	self assert: (regex matches: 'café').
	self deny: (regex matches: 'cafe')
]

{ #category : 'tests' }
PCRE2PatternConversionTest >> testUTF32LibraryCanUseConvertContext [

	| context regex |
	self skipUnlessUTF32PatternConversionSupported ifTrue: [ ^ self ].
	context := LibPCRE2UTF32 newConvertContext.
	context globEscape: $!.

	regex := PCRE2UTF32Compiler new compile:
		         (LibPCRE2UTF32 convertGlob: 'file!*.st' context: context).

	self assert: (regex matches: 'file*.st').
	self deny: (regex matches: 'fileABC.st')
]
