"
Tests for PCRE2's DFA matching mode, which can return several same-start alternatives for one match attempt.
"
Class {
	#name : 'PCRE2DFAMatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchAnswersStandaloneMatchData [

	| match regex subject |
	subject := 'the caterpillar catchment'.
	regex := 'cat(er(pillar)?)?' asPerlCompatibleRegex.

	match := regex dfaMatch: subject workspaceSize: 40 ovectorSize: 3.

	self assert: match count equals: 3.
	self assert: match readMatches equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchConvenienceSelectors [

	| regex |
	regex := 'cat(er(pillar)?)?' asPerlCompatibleRegex.

	self assert: (regex dfaMatch: 'the caterpillar catchment') readMatches equals: #( 'caterpillar' 'cater' 'cat' ).
	self assert: (regex dfaMatch: 'the caterpillar catchment' workspaceSize: 40) readMatches equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchValidatesWorkspaceAndOvectorSizes [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [ regex dfaMatches: 'a' workspaceSize: 19 ]
		raise: Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'greater than or equal to 20') ].
	self
		should: [ regex dfaMatch: 'a' workspaceSize: 20 ovectorSize: 0 ]
		raise: Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'positive integer') ]
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesDecodesUTF8Results [

	| eclair matches regex subject |
	eclair := (String with: (Character value: 16rE9)) , 'clair'.
	subject := 'un ' , eclair , ' ici'.
	regex := eclair asPerlCompatibleRegex.

	matches := regex dfaMatches: subject.

	self assert: matches equals: { eclair }
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesReturnsAllAlternativesAtFirstStart [

	| matches regex |
	regex := 'cat(er(pillar)?)?' asPerlCompatibleRegex.

	matches := regex dfaMatches: 'the caterpillar catchment' workspaceSize: 40 ovectorSize: 3.

	self assert: matches equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesReturnsEmptyArrayWhenThereIsNoMatch [

	self assert: ('dog' asPerlCompatibleRegex dfaMatches: 'the caterpillar catchment') equals: #(  )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testRegularMatchAfterSmallDFAMatchData [

	| dfaMatch regex regularMatch |
	regex := '(a)(b)(c)' asPerlCompatibleRegex.
	dfaMatch := regex dfaMatch: 'abc' workspaceSize: 40 ovectorSize: 1.

	regularMatch := regex findMatch: 'abc'.

	self assert: dfaMatch count equals: 1.
	self assert: regularMatch readMatches equals: #( 'abc' 'a' 'b' 'c' )
]
