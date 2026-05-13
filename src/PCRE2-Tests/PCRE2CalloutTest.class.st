"
I cover PCRE2 callout metadata APIs.

These tests intentionally start with passive callout enumeration, which inspects compiled patterns without installing runtime match callbacks. That gives debugger/explainer tools a safe first layer before we expose live match callouts.
"
Class {
	#name : 'PCRE2CalloutTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2CalloutTest >> testAutomaticCalloutsExposePatternProgressSites [

	| regex sites |
	regex := 'ab' asPerlCompatibleRegexWithOptions: PCRE2 autoCallout.
	sites := regex calloutSites.

	self assert: sites size equals: 3.
	self
		assert: (sites collect: [ :site | site patternPosition ])
		equals: #( 0 1 2 ).
	self assert: (sites allSatisfy: [ :site | site number = 255 ]).
	self assert: (regex matches: 'ab')
]

{ #category : 'tests' }
PCRE2CalloutTest >> testCalloutSitesDoEnumeratesInPatternOrder [

	| regex visited |
	regex := '(?C2)a(?C3)b' asPerlCompatibleRegex.
	visited := OrderedCollection new.

	regex calloutSitesDo: [ :site | visited add: site number ].

	self assert: visited asArray equals: #( 2 3 )
]

{ #category : 'tests' }
PCRE2CalloutTest >> testCalloutSitesDoNotAffectMatching [

	| regex |
	regex := '(?C1)a(?C"step")b' asPerlCompatibleRegex.

	self assert: regex calloutSites size equals: 2.
	self assert: (regex matches: 'ab').
	self deny: (regex matches: 'ac')
]

{ #category : 'tests' }
PCRE2CalloutTest >> testCalloutSitesExposeNumberedAndStringCallouts [

	| first regex second sites |
	regex := '(?C1)a(?C"step")b' asPerlCompatibleRegex.
	sites := regex calloutSites.
	first := sites first.
	second := sites second.

	self assert: sites size equals: 2.
	self assert: first version equals: 0.
	self assert: first number equals: 1.
	self deny: first hasString.
	self assert: first string isNil.
	self assert: first nextItemLength equals: 1.

	self assert: second version equals: 0.
	self assert: second number equals: 0.
	self assert: second hasString.
	self assert: second string equals: 'step'.
	self assert: second stringLength equals: 4.
	self assert: second stringOffset > 0.
	self assert: second patternPosition > first patternPosition
]
