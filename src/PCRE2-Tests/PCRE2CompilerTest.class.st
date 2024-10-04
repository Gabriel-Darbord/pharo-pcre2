Class {
	#name : 'PCRE2CompilerTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2CompilerTest >> testErrorCode [

	self
		should: [ '*' asPCRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
		self assert: (ex description endsWith: '(*ERROR)*') ].
	self
		should: [ '(' asPCRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
		self assert: (ex description endsWith: '((*ERROR)') ].
	self
		should: [ '(??)' asPCRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
		self assert: (ex description endsWith: '(?(*ERROR)?)') ].

	"not ASCII"
	self
		should: [ 'λ*φ(*)α' asPCRegex ]
		raise: PCRE2CompileError
		withExceptionDo: [ :ex |
		self assert: (ex description endsWith: 'λ*φ((*ERROR)*)α') ]
]

{ #category : 'tests' }
PCRE2CompilerTest >> testSharedDefaultCompiler [

	self assert: '' asPCRegex compiler identicalTo: '' asPCRegex compiler
]
