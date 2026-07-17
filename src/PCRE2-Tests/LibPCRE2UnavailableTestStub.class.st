"
Test library whose native runtime cannot be resolved.
"
Class {
	#name : 'LibPCRE2UnavailableTestStub',
	#superclass : 'LibPCRE2',
	#category : 'PCRE2-Tests-Support',
	#package : 'PCRE2-Tests',
	#tag : 'Support'
}

{ #category : 'testing' }
LibPCRE2UnavailableTestStub class >> isAbstract [

	^ true
]

{ #category : 'library path' }
LibPCRE2UnavailableTestStub >> ffiLibraryName [

	self error: 'Native PCRE2 library unavailable'
]
