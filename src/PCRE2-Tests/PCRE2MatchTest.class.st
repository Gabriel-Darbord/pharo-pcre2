"
Tests for standalone `PCRE2Match` behavior.

The suite covers offset access, persistent match data, remembered subjects, and decoded match/group reads.
"
Class {
	#name : 'PCRE2MatchTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTest >> testCount [

	| match regex |
	regex := 'a' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 1.

	regex := '(a+)' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 2.

	regex := '((a+)b(c+))*' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 4
]

{ #category : 'tests' }
PCRE2MatchTest >> testDuplicateNamedGroups [

	| match regex |
	regex := '(?<part>cat)|(?<part>dog)'
		         asPerlCompatibleRegexWithOptions: PCRE2 dupNames.
	match := regex findMatch: 'dog'.

	self assert: regex namedGroups equals: #( 'part' 'part' ).
	self assert: (match groupsNamed: 'part') equals: { nil. 'dog' }.
	self assert: (match groupNamed: 'part') equals: 'dog'
]

{ #category : 'tests' }
PCRE2MatchTest >> testLastMatchIndex [

	| match |
	match := 'bc' asPerlCompatibleRegex findMatch: 'abcde'.
	self assert: match lastMatchIndex equals: 3.
	match bePersistent.
	self assert: match lastMatchIndex equals: 3.

	match := 'é' asPerlCompatibleRegex findMatch: 'éé'.
	self assert: match lastMatchIndex equals: 2
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroups [

	| groups match regex |
	regex := '(?<word>\p{L}+)-(?<digits>\d+)' asPerlCompatibleRegex.
	match := regex findMatch: 'café-123'.

	self assert: regex namedGroups equals: #( 'word' 'digits' ).
	self assert: match namedGroups equals: regex namedGroups.
	self assert: (match groupAt: 0) equals: 'café-123'.
	self assert: (match groupAt: 1) equals: 'café'.
	self assert: (match groupNamed: 'word') equals: 'café'.
	self assert: (match groupNamed: 'digits') equals: '123'.
	self
		assert: (match groupNamed: 'missing' ifAbsent: [ 'absent' ])
		equals: 'absent'.

	groups := match groupsByName.
	self assert: (groups at: 'word') equals: 'café'.
	self assert: (groups at: 'digits') equals: '123'
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroupsAfterUnnamedCapture [

	| match regex |
	regex := '(a)(?<letter>b)' asPerlCompatibleRegex.
	match := regex findMatch: 'ab'.

	self assert: regex namedGroups size equals: 2.
	self assert: (regex namedGroups at: 1) equals: nil.
	self assert: (regex namedGroups at: 2) equals: 'letter'.
	self assert: (match groupNamed: 'letter') equals: 'b'
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroupsSurvivePersistence [

	| match |
	match := '(?<word>\w+)' asPerlCompatibleRegex findMatch: 'hello'.
	match bePersistent.

	self assert: match isPersistent.
	self assert: (match groupNamed: 'word') equals: 'hello'.
	self assert: (match groupsByName at: 'word') equals: 'hello'
]

{ #category : 'tests' }
PCRE2MatchTest >> testOffsetsAt [

	| match regex |
	regex := '((a+)b(c+))*' asPerlCompatibleRegex.
	match := regex findMatch: 'aabccc'.

	self assert: (match offsetsAt: 1) equals: { 0. 6 }.
	self assert: (match offsetsAt: 2) equals: { 0. 6 }.
	self assert: (match offsetsAt: 3) equals: { 0. 2 }.
	self assert: (match offsetsAt: 4) equals: { 3. 6 }
]

{ #category : 'tests' }
PCRE2MatchTest >> testStandaloneMatchKeepsItsOwnResult [

	| firstMatch regex secondMatch |
	regex := '(\w+)' asPerlCompatibleRegex.

	firstMatch := regex findMatch: 'one'.
	secondMatch := regex findMatch: 'two'.

	self assert: firstMatch readMatches equals: #( 'one' 'one' ).
	self assert: secondMatch readMatches equals: #( 'two' 'two' )
]
