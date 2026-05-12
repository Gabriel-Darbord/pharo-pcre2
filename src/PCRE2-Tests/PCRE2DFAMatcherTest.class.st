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
PCRE2DFAMatcherTest >> testDFAMatchPopulatesExplicitMatchData [

	| regex rc subject |
	subject := 'the caterpillar catchment'.
	regex := 'cat(er(pillar)?)?' asPCRegex.

	rc := regex dfaMatch: subject workspaceSize: 40 ovectorSize: 3.

	self assert: rc equals: 3.
	self
		assert: (regex matchData readMatches: subject)
		equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesDecodesUTF8Results [

	| eclair matches regex subject |
	eclair := (String with: (Character value: 16rE9)) , 'clair'.
	subject := 'un ' , eclair , ' ici'.
	regex := eclair asPCRegex.

	matches := regex dfaMatches: subject.

	self assert: matches equals: { eclair }
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesReturnsAllAlternativesAtFirstStart [

	| matches regex |
	regex := 'cat(er(pillar)?)?' asPCRegex.

	matches := regex
		           dfaMatches: 'the caterpillar catchment'
		           workspaceSize: 40
		           ovectorSize: 3.

	self assert: matches equals: #( 'caterpillar' 'cater' 'cat' )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testDFAMatchesReturnsEmptyArrayWhenThereIsNoMatch [

	self
		assert: ('dog' asPCRegex dfaMatches: 'the caterpillar catchment')
		equals: #(  )
]

{ #category : 'tests' }
PCRE2DFAMatcherTest >> testRegularMatchRefreshesTooSmallDFAMatchData [

	| regex |
	regex := '(a)(b)(c)' asPCRegex.
	regex dfaMatch: 'abc' workspaceSize: 40 ovectorSize: 1.

	self
		assert: (regex findWithGroups: 'abc')
		equals: #( 'abc' 'a' 'b' 'c' )
]
