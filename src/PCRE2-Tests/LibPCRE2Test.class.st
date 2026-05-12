Class {
	#name : 'LibPCRE2Test',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
LibPCRE2Test >> testConfig [

	self
		shouldnt: [ LibPCRE2 uniqueInstance allConfigs ]
		raise: PCRE2Error.
	self shouldnt: [ LibPCRE2 assertCompatibleLibrary ] raise: PCRE2Error.
	self assert: LibPCRE2 versionString notEmpty.
	self
		assert: LibPCRE2 versionMajor
		equals: LibPCRE2 requiredMajorVersion.
	self assert: LibPCRE2 versionMinor isInteger.
	self assert: LibPCRE2 versionDate notEmpty.
	self assert: LibPCRE2 supports8BitCodeUnitWidth.
	self assert: LibPCRE2 supportsUnicode
]
