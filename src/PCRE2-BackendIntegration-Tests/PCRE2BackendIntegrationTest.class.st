"
Coexistence of the FFI and the Pharo backend in one image: that objects of one backend are refused by the other, and that choosing a backend explicitly survives changes to the global default. Loaded only when both implementations are available.

Behavior the two backends must agree on belongs in PCRE2BackendParityTest and PCRE2BackendWidthParityTest.
"
Class {
	#name : 'PCRE2BackendIntegrationTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-BackendIntegration-Tests',
	#package : 'PCRE2-BackendIntegration-Tests'
}

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testContextRolesAreChecked [

	| compiler matcher |
	compiler := PCRE2Compiler new.
	matcher := compiler compile: 'a'.
	self should: [ matcher context: compiler context ] raise: PCRE2Error.
	self should: [ compiler context: matcher context ] raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testCrossBackendContextsAndMatchDataAreRejected [

	| ffi pharo data |
	ffi := PCRE2Compiler new
		       backend: PCRE2CompilerFFIBackend;
		       compile: 'a'.
	pharo := PCRE2Compiler new
		         backend: PCRE2CompilerPharoBackend;
		         compile: 'a'.
	self should: [ ffi context: pharo context ] raise: PCRE2Error.
	self should: [ pharo context: ffi context ] raise: PCRE2Error.
	data := pharo newMatchData.
	self
		should: [
				ffi
					matchBytes: #[ 97 ]
					from: 1
					to: 1
					into: data ]
		raise: PCRE2Error.
	data := ffi newMatchData.
	self
		should: [
				pharo
					matchBytes: #[ 97 ]
					from: 1
					to: 1
					into: data ]
		raise: PCRE2Error
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testFFIContextRestoreDoesNotFollowTheGlobalDefault [

	| original context |
	original := PCRE2Compiler defaultBackend.
	context := (PCRE2Compiler new backend: PCRE2CompilerFFIBackend) context.
	context newline: PCRE2 newlineCR.
	context free.
	context getHandle beNull.
	[
		PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
		context restoreAfterStartup.
		self deny: context isNull.
		self assert: context newline equals: PCRE2 newlineCR ] ensure: [ PCRE2Compiler defaultBackend: original ]
]

{ #category : 'tests' }
PCRE2BackendIntegrationTest >> testTemporaryCompilersPreserveTheSelectedBackend [

	| original matcher trace |
	original := PCRE2Compiler defaultBackend.
	matcher := PCRE2Compiler new
		           backend: PCRE2CompilerFFIBackend;
		           compile: 'a'.
	[
		PCRE2Compiler defaultBackend: PCRE2CompilerPharoBackend.
		trace := matcher traceMatch: 'a'.
		self assert: trace match readMatch equals: 'a'.
		self assert: (matcher backend isKindOf: PCRE2MatcherFFIBackend) ] ensure: [ PCRE2Compiler defaultBackend: original ]
]
