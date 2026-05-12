"
Tests for PCRE2 partial matching.

Partial matching is PCRE2-specific: soft mode prefers a complete match when one exists, while hard mode reports a partial match when additional subject bytes could extend or change the match.
"
Class {
	#name : 'PCRE2PartialMatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testCompleteMatchingIgnoresPartialResult [

	| regex |
	regex := 'abc' asPerlCompatibleRegex.
	regex addOptions: PCRE2 partialSoft.

	self deny: (regex matches: 'ab').
	self deny: (regex matchesPrefix: 'ab')
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testHardPartialMatchCanPreferExtendableCompleteMatch [

	| match |
	match := 'ab+' asPerlCompatibleRegex findHardPartialMatch: 'ab'.

	self assert: match isPartial.
	self deny: match isComplete.
	self assert: match readMatch equals: 'ab'
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testPartialMatchDecodesUTF8Subject [

	| match |
	match := 'éclair' asPerlCompatibleRegex findPartialMatch: 'éc'.

	self assert: match isPartial.
	self assert: match readMatch equals: 'éc'
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testPartialMatchReturnsNilWhenNoMatchCanStart [

	self
		assert: ('abc' asPerlCompatibleRegex findPartialMatch: 'ax')
		equals: nil
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testPartialMatchWorksWithDefaultJITCompiler [

	| match regex |
	regex := 'abc' asPerlCompatibleRegex.
	match := regex findPartialMatch: 'ab'.

	self assert: match isPartial.
	self assert: match readMatch equals: 'ab'
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testSoftPartialMatch [

	| match |
	match := 'abc' asPerlCompatibleRegex findPartialMatch: 'ab'.

	self deny: match equals: nil.
	self assert: match isPartial.
	self deny: match isComplete.
	self assert: match resultCode equals: PCRE2 errorPartial.
	self assert: match readMatch equals: 'ab'
]

{ #category : 'tests' }
PCRE2PartialMatcherTest >> testSoftPartialMatchPrefersCompleteMatch [

	| match |
	match := 'ab+' asPerlCompatibleRegex findSoftPartialMatch: 'ab'.

	self deny: match isPartial.
	self assert: match isComplete.
	self assert: match readMatch equals: 'ab'
]
