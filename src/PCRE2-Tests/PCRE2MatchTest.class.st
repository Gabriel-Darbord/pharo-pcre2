Class {
	#name : 'PCRE2MatchTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTest >> testCount [

	| regex |
	regex := 'a' asPCRegex.
	regex matches: 'abc'.
	self assert: regex matchData count equals: 1.

	regex := '(a+)' asPCRegex.
	regex matches: 'abc'.
	self assert: regex matchData count equals: 2.

	regex := '((a+)b(c+))*' asPCRegex.
	regex matches: 'abc'.
	self assert: regex matchData count equals: 4
]

{ #category : 'tests' }
PCRE2MatchTest >> testOffsetsAt [

	| regex |
	regex := '((a+)b(c+))*' asPCRegex.
	regex matches: 'aabccc'.
	self assert: (regex matchData offsetsAt: 1) equals: { 0. 6 }.
	self assert: (regex matchData offsetsAt: 2) equals: { 0. 6 }.
	self assert: (regex matchData offsetsAt: 3) equals: { 0. 2 }.
	self assert: (regex matchData offsetsAt: 4) equals: { 3. 6 }
]
