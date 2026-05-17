"
I cover opt-in PCRE2 match tracing.

Tracing compiles a temporary matcher with automatic callouts and no JIT so debugger tools can inspect runtime callout events without changing the normal matcher used by application code.
"
Class {
	#name : 'PCRE2MatchTraceTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceCorrelatesEventsWithStaticSites [

	| numbers sites trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	numbers := OrderedCollection new.
	sites := OrderedCollection new.

	trace eventsWithSitesDo: [ :event :site |
		self assert: site notNil.
		self assert: (site matchesEvent: event).
		numbers add: event number.
		sites add: site ].

	self assert: (numbers includes: 1).
	self assert: (numbers includes: PCRE2 automaticCalloutNumber).
	self assert:
		(sites includes: (trace calloutSiteForEvent: trace events first))
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceIterationConveniences [

	| events stepKinds stepIndexes steps trace |
	trace := 'ab' asPerlCompatibleRegex traceMatch: 'ab'.
	events := OrderedCollection new.
	steps := OrderedCollection new.

	trace eventsDo: [ :event | events add: event ].
	trace stepsDo: [ :step | steps add: step ].
	stepIndexes := steps collect: [ :step | step index ].
	stepKinds := steps collect: [ :step | step kind ].

	self assert: trace input notNil.
	self deny: trace isPartial.
	self assert: events asArray equals: trace events.
	self assert: steps size equals: trace steps size.
	self
		assert: stepIndexes asArray
		equals: ((1 to: steps size) collect: [ :each | each ]) asArray.
	self
		assert: stepKinds asArray
		equals: (trace steps collect: [ :step | step kind ])
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchCollectsAutomaticCalloutEvents [

	| regex trace |
	regex := 'ab' asPerlCompatibleRegex.
	trace := regex traceMatch: 'ab'.

	self assert: trace isMatch.
	self assert: trace isFullMatch.
	self assert: trace matchedString equals: 'ab'.
	self assert: trace resultCode > 0.
	self assert: trace events notEmpty.
	self assert: trace calloutSites notEmpty.
	self assert:
		(trace calloutSites allSatisfy: [ :site | site isAutomatic ]).
	self assert:
		(trace events allSatisfy: [ :event | event isAutomatic ]).
	self assert:
		(trace events anySatisfy: [ :event | event eventKind = #startMatch ])
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchDoesNotMutateOriginalMatcher [

	| options regex trace |
	regex := 'a' asPerlCompatibleRegex.
	options := regex options.
	self assert: regex calloutSites isEmpty.

	trace := regex traceMatch: 'a'.

	self assert: trace isMatch.
	self assert: regex options equals: options.
	self assert: regex calloutSites isEmpty.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchPreservesCompileContext [

	| compiler regex subject trace |
	compiler := PCRE2Compiler new.
	compiler context useBSRAnyCRLF.
	regex := compiler compile: '\R'.
	subject := String with: (Character value: 16r85).

	trace := regex traceMatch: subject.

	self deny: (regex matches: subject).
	self deny: trace isMatch
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchPreservesCompileOptions [

	| regex trace |
	regex := 'a' asPerlCompatibleRegexWithOptions: PCRE2 caseless.

	trace := regex traceMatch: 'A'.

	self assert: trace isMatch.
	self assert: trace matchedString equals: 'A'
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceMatchReportsNoMatchWithEvents [

	| trace |
	trace := 'ab' asPerlCompatibleRegex traceMatch: 'a'.

	self deny: trace isMatch.
	self assert: trace match isNil.
	self assert: trace resultCode equals: PCRE2 errorNoMatch.
	self assert: trace events notEmpty
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceStepsDescribeRuntimeEvents [

	| captureStep steps trace |
	trace := '(?C1)(a)(?C2)b' asPerlCompatibleRegex traceMatch: 'ab'.
	steps := trace steps.

	self assert: steps size equals: trace events size.
	self assert: steps first index equals: 1.
	self assert: steps first event equals: trace events first.
	self
		assert: steps first site
		equals: (trace calloutSiteForEvent: trace events first).
	self assert: steps first isStartMatch.
	self assert: steps first hasSite.
	self assert: steps first subjectPosition equals: 1.

	captureStep := steps detect: [ :step | step event number = 2 ].
	self assert: captureStep isProgress.
	self assert: (captureStep captureRangeAt: 1) equals: (1 to: 1).
	self assert: captureStep subjectRange equals: (1 to: 1)
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceStepsPreserveMarks [

	| step trace |
	trace := '(*MARK:before)(?C1)a' asPerlCompatibleRegex traceMatch: 'a'.
	step := trace steps detect: [ :each | each event number = 1 ].

	self assert: step mark equals: 'before'
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceStepsRepresentUnsetCapturesAsNil [

	| step trace |
	trace := '(?C1)(a)?(?C2)b' asPerlCompatibleRegex traceMatch: 'b'.
	step := trace steps detect: [ :each | each event number = 2 ].

	self assert: step fullMatchRange isNil.
	self assert: (step captureRangeAt: 1) isNil
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceStepsTranslateUTF8PatternRanges [

	| steps trace |
	trace := 'éa' asPerlCompatibleRegex traceMatch: 'éa'.
	steps := trace steps.

	self assert: steps first patternRange equals: (1 to: 1).
	self assert: steps second patternRange equals: (2 to: 2).
	self assert: (steps allSatisfy: [ :step | step site isAutomatic ])
]

{ #category : 'tests' }
PCRE2MatchTraceTest >> testTraceTranslatesUTF8EventPositions [

	| event trace |
	trace := '(?C1)é(?C2)a' asPerlCompatibleRegex traceMatch: 'éa'.
	event := trace events detect: [ :each | each number = 2 ].

	self assert: event currentPosition equals: 2.
	self
		assert: (trace subjectCharacterPositionForCodeUnitOffset:
				 event currentPosition)
		equals: 2.
	self assert: (trace subjectCharacterPositionAtEvent: event) equals: 2.
	self
		assert: (trace subjectCharacterRangeFromStartOffset: 0 endOffset: 2)
		equals: (1 to: 1)
]
