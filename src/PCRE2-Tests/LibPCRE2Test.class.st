"
Tests for the native PCRE2 library bridge.

These checks verify that the loaded library exposes the expected runtime configuration for the binding.
"
Class {
	#name : 'LibPCRE2Test',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
LibPCRE2Test >> testConfig [

	| configs supportsJIT version |
	self assert: LibPCRE2 isAbstract.
	self deny: LibPCRE2UTF8 isAbstract.

	version := LibPCRE2 version.
	configs := LibPCRE2UTF8 uniqueInstance allConfigs.

	self assert: LibPCRE2UTF8 requiredMajorVersion equals: 10.
	self assert: LibPCRE2 versionMajor equals: LibPCRE2UTF8 requiredMajorVersion.
	self assert: version first equals: LibPCRE2 versionMajor.
	self assert: version second equals: LibPCRE2 versionMinor.
	self assert: version third equals: LibPCRE2 versionDate.
	self assert: (LibPCRE2 versionString beginsWith: LibPCRE2UTF8 requiredMajorVersion asString , '.').
	self assert: configs size equals: 16.

	LibPCRE2UTF8 assertCompatibleLibrary.
	self assert: LibPCRE2 supportsUnicode.
	self assert: LibPCRE2 supports8BitCodeUnitWidth.
	self assert: LibPCRE2UTF8 supportsCodeUnitWidth.
	supportsJIT := LibPCRE2 supportsJIT.
	self assert: (supportsJIT == true or: [ supportsJIT == false ])
]

{ #category : 'tests' }
LibPCRE2Test >> testNewMatchContext [

	| context |
	context := LibPCRE2UTF8 newMatchContext.
	self deny: context isNull.
	self assert: context class equals: PCRE2UTF8MatchContext
]

{ #category : 'tests' }
LibPCRE2Test >> testSerializeDeserializeConvenienceDecodesAllCodes [

	| bytes handles pointers regexes wordSize |
	regexes := {
		           'a+' asPerlCompatibleRegex.
		           'b+' asPerlCompatibleRegex }.
	bytes := LibPCRE2UTF8 serialize: regexes.

	pointers := LibPCRE2UTF8 deserialize: bytes.
	wordSize := ExternalAddress wordSize.
	handles := (1 to: regexes size) collect: [ :index | pointers pointerAtOffset: wordSize * (index - 1) ].

	[
		self assert: pointers size equals: regexes size * wordSize.
		handles do: [ :handle | self deny: handle isNull ] ] ensure: [
		handles do: [ :handle | (PCRE2UTF8Matcher fromHandle: handle) finalize ] ]
]
