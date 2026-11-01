"
Abstract parent of the tests for the C binding.

This package tests `PCRE2-FFIBackend`, so every case here runs on that backend whatever the image default is. Without this, a build that also loads the Pharo engine makes that engine the default, and these tests quietly exercise it instead of the binding they are named for: the C binding would then only ever be tested by the FFI-only CI job.

Pinning is scoped to the case, so it does not leak into other packages' tests.
"
Class {
	#name : 'PCRE2FFITestCase',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'testing' }
PCRE2FFITestCase class >> isAbstract [

	^ self == PCRE2FFITestCase
]

{ #category : 'running' }
PCRE2FFITestCase >> runCase [
	"Run this case on the FFI backend whatever the image default is. See the class comment."

	^ PCRE2Compiler withDefaultBackend: PCRE2CompilerFFIBackend do: [ super runCase ]
]
