"
Test compiler that models an unavailable native PCRE2 library.
"
Class {
	#name : 'PCRE2CompilerWithoutNativeLibraryTestStub',
	#superclass : 'AnObsoletePCRE2Compiler',
	#category : 'PCRE2-Tests-Support',
	#package : 'PCRE2-Tests',
	#tag : 'Support'
}

{ #category : 'testing' }
PCRE2CompilerWithoutNativeLibraryTestStub class >> isAbstract [

	^ true
]

{ #category : 'testing' }
PCRE2CompilerWithoutNativeLibraryTestStub class >> nativeLibraryAvailable [

	^ false
]
