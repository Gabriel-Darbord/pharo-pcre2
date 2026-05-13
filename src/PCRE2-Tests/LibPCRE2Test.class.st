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
	version := LibPCRE2 version.
	configs := LibPCRE2 uniqueInstance allConfigs.

	self assert: LibPCRE2 requiredMajorVersion equals: 10.
	self
		assert: LibPCRE2 versionMajor
		equals: LibPCRE2 requiredMajorVersion.
	self assert: version first equals: LibPCRE2 versionMajor.
	self assert: version second equals: LibPCRE2 versionMinor.
	self assert: version third equals: LibPCRE2 versionDate.
	self assert: (LibPCRE2 versionString beginsWith:
			 LibPCRE2 requiredMajorVersion asString , '.').
	self assert: configs size equals: 16.

	LibPCRE2 assertCompatibleLibrary.
	self assert: LibPCRE2 supportsUnicode.
	self assert: LibPCRE2 supports8BitCodeUnitWidth.
	supportsJIT := LibPCRE2 supportsJIT.
	self assert: (supportsJIT == true or: [ supportsJIT == false ])
]

{ #category : 'tests' }
LibPCRE2Test >> testNewMatchContext [

	| context |
	context := LibPCRE2 newMatchContext.
	self deny: context isNull
]
