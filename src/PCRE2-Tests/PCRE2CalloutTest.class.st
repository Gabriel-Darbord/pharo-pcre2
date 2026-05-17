"
I cover PCRE2 callout metadata and runtime callback APIs.

Passive enumeration tests inspect compiled patterns without installing match callbacks. Runtime tests verify the explicit callback behavior used by tracing and debugging tools.
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
	self assert: (sites allSatisfy: [ :site |
			 site number = PCRE2 automaticCalloutNumber ]).
	self assert: (sites allSatisfy: [ :site | site isAutomatic ]).
	self assert: (regex matches: 'ab')
]

{ #category : 'tests' }
PCRE2CalloutTest >> testCalloutConvenienceVariantsUseTemporaryCallbacks [

	| bytes events regex |
	regex := '(?C1)a+' asPerlCompatibleRegex.
	bytes := ZnUTF8Encoder default encodeString: 'aaa'.
	events := OrderedCollection new.

	self
		assert: (regex find: 'zaa' calloutsDo: [ :event |
				 events add: event.
				 0 ])
		equals: 'aa'.
	self
		assert: (regex findAll: 'a aa' calloutsDo: [ :event |
				 events add: event.
				 0 ]) asArray
		equals: #( 'a' 'aa' ).
	self assert: (regex matchesPrefix: 'aaa!' calloutsDo: [ :event |
			 events add: event.
			 0 ]).
	self assert: (regex search: 'zaa' calloutsDo: [ :event |
			 events add: event.
			 0 ]).
	self
		assert: (regex
				 matchBytes: bytes
				 from: 1
				 to: bytes size
				 calloutsDo: [ :event |
					 events add: event.
					 0 ]) readMatch
		equals: bytes.

	self assert: events size >= 5.
	self assert: (regex matches: 'aaa')
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

{ #category : 'tests' }
PCRE2CalloutTest >> testFindMatchCalloutsDoAnswersStandaloneMatch [

	| events match regex |
	regex := '(a)(?C7)b' asPerlCompatibleRegex.
	events := OrderedCollection new.

	match := regex findMatch: 'zab' calloutsDo: [ :event |
		         events add: event.
		         0 ].
	self assert: match readMatch equals: 'ab'.
	self assert: match readMatches equals: #( 'ab' 'a' ).
	self assert: events size equals: 1.
	self assert: events first number equals: 7
]

{ #category : 'tests' }
PCRE2CalloutTest >> testMatcherCalloutsDoCanAbortWithCalloutError [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	events := OrderedCollection new.

	self
		should: [
			regex matches: 'ab' calloutsDo: [ :event |
				events add: event.
				PCRE2 errorCallout ] ]
		raise: PCRE2MatchError
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'callout error code' ].
	self assert: events size equals: 1.
	self assert: (regex matches: 'ab')
]

{ #category : 'tests' }
PCRE2CalloutTest >> testMatcherCalloutsDoCanAbortWithNoMatch [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	events := OrderedCollection new.

	self deny: (regex matches: 'ab' calloutsDo: [ :event |
			 events add: event.
			 PCRE2 errorNoMatch ]).
	self assert: events size equals: 1.
	self assert: (regex matches: 'ab')
]

{ #category : 'tests' }
PCRE2CalloutTest >> testMatcherCalloutsDoInvokesCallbackTemporarily [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	events := OrderedCollection new.

	self assert: (regex matches: 'ab' calloutsDo: [ :event |
			 events add: event.
			 nil ]).
	self assert: events size equals: 1.
	self assert: events first number equals: 1.
	self assert: (regex matches: 'ab').
	self assert: events size equals: 1
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutCanAbortWithCalloutError [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.
	regex context calloutBlock: [ :event |
		events add: event.
		PCRE2 errorCallout ].

	self
		should: [ regex matches: 'ab' ]
		raise: PCRE2MatchError
		withExceptionDo: [ :error |
			self assert: error messageText equals: 'callout error code' ].
	self assert: events size equals: 1
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutCanAbortWithNoMatch [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.
	regex context calloutBlock: [ :event |
		events add: event.
		PCRE2 errorNoMatch ].

	self deny: (regex matches: 'ab').
	self assert: events size equals: 1
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutCanBeCleared [

	| events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.
	regex context calloutBlock: [ :event |
		events add: event.
		0 ].
	regex context clearCallout.

	self assert: (regex matches: 'ab').
	self assert: events isEmpty
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutReceivesMatchState [

	| events first regex second sites |
	regex := '(?C1)a(?C"step")b' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	sites := regex calloutSites.
	events := OrderedCollection new.
	regex context calloutBlock: [ :event |
		events add: event.
		0 ].

	self assert: (regex matches: 'ab').
	self assert: events size equals: 2.
	first := events first.
	second := events second.
	self assert: first version equals: 2.
	self assert: first number equals: 1.
	self assert: first subjectLength equals: 2.
	self assert: first startMatch equals: 0.
	self assert: first currentPosition equals: 0.
	self assert: first isStartMatch.
	self deny: first isBacktrack.
	self deny: first hasString.
	self
		assert: first patternPosition
		equals: sites first patternPosition.

	self assert: second number equals: 0.
	self assert: second string equals: 'step'.
	self assert: second currentPosition equals: 1.
	self
		assert: second patternPosition
		equals: sites second patternPosition
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutReportsBacktracking [

	| events regex |
	regex := '(?C1)(a(?C2)b|a(?C3)c)' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.
	regex context calloutBlock: [ :event |
		events add: event.
		0 ].

	self assert: (regex matches: 'ac').
	self
		assert: (events collect: [ :event | event number ]) asArray
		equals: #( 1 2 3 ).
	self assert: events first isStartMatch.
	self deny: events first isBacktrack.
	self assert: events first eventKind equals: #startMatch.
	self assert: events second eventKind equals: #progress.
	self assert: events third isBacktrack.
	self assert: events third eventKind equals: #backtrack
]

{ #category : 'tests' }
PCRE2CalloutTest >> testRuntimeCalloutReportsMarksAndCaptures [

	| event events regex |
	regex := '(*MARK:before)(a)(?C1)b' asPerlCompatibleRegex.
	regex addOptions: PCRE2 noJIT.
	events := OrderedCollection new.
	regex context calloutBlock: [ :each |
		events add: each.
		0 ].

	self assert: (regex matches: 'ab').
	event := events first.
	self assert: event mark equals: 'before'.
	self assert: event captureTop equals: 2.
	self assert: event captureLast equals: 1.
	self assert: (event offsetsAt: 2) equals: #( 0 1 )
]

{ #category : 'tests' }
PCRE2CalloutTest >> testWithAutomaticCalloutsDoGeneratesCallbacksWithoutChangingReceiver [

	| events regex result |
	regex := 'ab' asPerlCompatibleRegex.
	events := OrderedCollection new.

	result := regex
		          withAutomaticCallouts: [ :event |
			          events add: event.
			          0 ]
		          do: [ :callbackMatcher | callbackMatcher matches: 'ab' ].
	self assert: result.
	self assert: events size >= 3.
	self assert: (events allSatisfy: [ :event | event isAutomatic ]).
	self assert: regex calloutSites isEmpty
]

{ #category : 'tests' }
PCRE2CalloutTest >> testWithCalloutDoSupportsCustomOperation [

	| answer events regex |
	regex := '(?C1)ab' asPerlCompatibleRegex.
	events := OrderedCollection new.

	answer := regex
		          withCallout: [ :event |
			          events add: event.
			          0 ]
		          do: [ :callbackMatcher | callbackMatcher find: 'zab' ].
	self assert: answer equals: 'ab'.
	self assert: events size equals: 1
]
