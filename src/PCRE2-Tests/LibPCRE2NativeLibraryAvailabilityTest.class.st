"
Tests native PCRE2 library discovery without requiring the library to be installed.
"
Class {
	#name : 'LibPCRE2NativeLibraryAvailabilityTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
LibPCRE2NativeLibraryAvailabilityTest >> testAnswersFalseWhenNativeLibraryCannotBeResolved [

	self deny: LibPCRE2UnavailableTestStub isNativeLibraryAvailable
]
