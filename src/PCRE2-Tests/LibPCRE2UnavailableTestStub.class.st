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

	^ false
]

{ #category : 'library path' }
LibPCRE2UnavailableTestStub >> nativeLibraryPath [

	^ nil
]
