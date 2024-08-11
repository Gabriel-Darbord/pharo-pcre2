Class {
	#name : 'PCRE2Test',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2Test >> testOptionsFor [

	self assert: (PCRE2 optionsFor: #compile) size equals: 30.
	self assert: (PCRE2 optionsFor: #jit_compile) size equals: 3.
	self assert: (PCRE2 optionsFor: #match) size equals: 12.
	self assert: (PCRE2 optionsFor: #jit_match) size equals: 8.
	self assert: (PCRE2 optionsFor: #dfa_match) size equals: 12.
	self assert: (PCRE2 optionsFor: #substitute) size equals: 11.
	self assert: (PCRE2 optionsFor: #convert) size equals: 7
]
