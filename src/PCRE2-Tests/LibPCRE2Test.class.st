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
		raise: PCRE2Error
]
