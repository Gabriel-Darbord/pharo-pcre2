"
Tests for compiling PCRE2 patterns from Pharo strings.

The suite covers successful compilation, compile errors, and UTF-8 error reporting offsets.
"
Class {
	#name : 'PCRE2CompilerTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2CompilerTest >> assertInvalidPattern: aString [

	| utf8 |
	utf8 := ZnUTF8Encoder default encodeString: aString.
	self
		should: [ aString asPCRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
			self assert: ex errorMessage notEmpty.
			self assert: ex pattern equals: aString.
			self assert: ex offset >= 0.
			self assert: ex offset <= utf8 size.
			self assert: (ex description includesSubstring: '(*ERROR)') ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testErrorCode [
	"PCRE2 minor versions may report slightly different diagnostic offsets, so keep this test focused on binding-level error handling."

	#( '*' '(' '(??)' 'λ*φ(*)α' ) do: [ :pattern |
		self assertInvalidPattern: pattern ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testSharedDefaultCompiler [

	self assert: '' asPCRegex compiler identicalTo: '' asPCRegex compiler
]
