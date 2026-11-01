"
Protects backend ownership through the FFI backend: that a compiler's backend choice reaches its matchers and matches, that it cannot be changed once a context exists, and that the public objects stay ordinary Pharo objects rather than external references.

Which backend an image picks when several are loaded belongs in PCRE2BackendIntegrationTest, which loads only when they both are.
"
Class {
	#name : 'PCRE2CompilerBackendTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2CompilerBackendTest >> testBackendMustBeSelectedBeforeContextCreation [

	| compiler |
	compiler := PCRE2Compiler new.
	compiler context.
	self should: [ compiler backend: PCRE2CompilerFFIBackend ] raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2CompilerBackendTest >> testExplicitBackendPropagatesToMatches [

	| compiler matcher match |
	compiler := PCRE2Compiler new backend: PCRE2CompilerFFIBackend.
	matcher := compiler compile: '(?<word>\w+)'.
	match := matcher findMatch: 'hello'.
	self assert: matcher compiler identicalTo: compiler.
	self assert: (matcher backend isKindOf: PCRE2MatcherFFIBackend).
	self assert: (match backend isKindOf: PCRE2MatchFFIBackend).
	self assert: (match groupNamed: 'word') equals: 'hello'
]

{ #category : 'tests' }
PCRE2CompilerBackendTest >> testMatchResultsRemainIndependent [

	| matcher first second |
	matcher := PCRE2Compiler new
		           backend: PCRE2CompilerFFIBackend;
		           compile: '\d+'.
	first := matcher findMatch: 'a12'.
	second := matcher findMatch: 'b345'.
	self deny: first backend identicalTo: second backend.
	self assert: first readMatch equals: '12'.
	self assert: second readMatch equals: '345'
]

{ #category : 'tests' }
PCRE2CompilerBackendTest >> testPublicObjectsAreNotExternalReferences [

	self deny: (PCRE2Matcher inheritsFrom: FFIExternalReference).
	self deny: (PCRE2Match inheritsFrom: FFIExternalReference)
]

{ #category : 'tests' }
PCRE2CompilerBackendTest >> testRecompiledMatcherSurvivesCollectionOfTemporaryHandles [

	| matcher |
	matcher := 'a+' asPerlCompatibleRegex.
	matcher recompile.
	Smalltalk garbageCollect.
	self assert: (matcher matches: 'aaa')
]
