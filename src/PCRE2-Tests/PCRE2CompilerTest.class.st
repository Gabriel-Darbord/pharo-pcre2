Class {
	#name : 'PCRE2CompilerTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2CompilerTest >> testSharedDefaultCompiler [

	self assert: '' asPCRegex compiler identicalTo: '' asPCRegex compiler
]
