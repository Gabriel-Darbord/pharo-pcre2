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

{ #category : 'tests' }
LibPCRE2NativeLibraryAvailabilityTest >> testAnswersTrueWhenNativeLibraryCanBeResolved [

	LibPCRE2UTF8 isNativeLibraryAvailable ifFalse: [ self skip ].
	self assert: LibPCRE2UTF8 isNativeLibraryAvailable
]

{ #category : 'tests' }
LibPCRE2NativeLibraryAvailabilityTest >> testCompilerStartupToleratesUnavailableNativeLibrary [

	[
		PCRE2CompilerWithoutNativeLibraryTestStub startUp: true.
		self deny: PCRE2Compiler supportsJIT ] ensure: [ PCRE2Compiler startUp: true ]
]
