Class {
	#name : 'PCRE2MatchTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTest >> testCount [

	| match regex |
	regex := 'a' asPCRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 1.

	regex := '(a+)' asPCRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 2.

	regex := '((a+)b(c+))*' asPCRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 4
]

{ #category : 'tests' }
PCRE2MatchTest >> testOffsetsAt [

	| match regex |
	regex := '((a+)b(c+))*' asPCRegex.
	match := regex findMatch: 'aabccc'.

	self assert: (match offsetsAt: 1) equals: { 0. 6 }.
	self assert: (match offsetsAt: 2) equals: { 0. 6 }.
	self assert: (match offsetsAt: 3) equals: { 0. 2 }.
	self assert: (match offsetsAt: 4) equals: { 3. 6 }
]

{ #category : 'tests' }
PCRE2MatchTest >> testStandaloneMatchKeepsItsOwnResult [

	| firstMatch regex secondMatch |
	regex := '(\w+)' asPCRegex.

	firstMatch := regex findMatch: 'one'.
	secondMatch := regex findMatch: 'two'.

	self assert: firstMatch readMatches equals: #( 'one' 'one' ).
	self assert: secondMatch readMatches equals: #( 'two' 'two' )
]
