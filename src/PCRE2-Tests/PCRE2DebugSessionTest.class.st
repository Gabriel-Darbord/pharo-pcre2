"
Tests for the PCRE2-Tools debugger session and presenter wiring.

These tests stay headless: they verify the model and presenter objects without opening Morphic windows.
"
Class {
	#name : 'PCRE2DebugSessionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'helpers' }
PCRE2DebugSessionTest >> assertContextText: aText highlights: expectedSubstring at: highlightInterval [

	| attributes |
	self
		assert: (aText asString
				 copyFrom: highlightInterval first
				 to: highlightInterval last)
		equals: expectedSubstring.
	attributes := aText attributesAt: highlightInterval first.
	self assert:
		(attributes anySatisfy: [ :each | each isKindOf: TextColor ]).
	self assert:
		(attributes anySatisfy: [ :each |
			 each isKindOf: TextBackgroundColor ])
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebugSessionSelectStepUsesStableStepIndex [

	| externalStep session |
	session := PCRE2DebugSession
		           pattern: '(cat|cater|caterpillar)'
		           subject: 'caterpillar'.
	session runTrace.
	externalStep := session trace steps second.

	session selectStep: externalStep.
	self assert: session selectedStepIndex equals: externalStep index.
	self assert: session selectedStep index equals: externalStep index
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterInputsHaveHelpText [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.

	self
		assert: presenter patternInput help
		equals: presenter patternInputHelpString.
	self
		assert: presenter subjectText help
		equals: presenter subjectInputHelpString
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterRowSelectionUpdatesSessionStepIndex [

	| presenter row session |
	session := PCRE2DebugSession
		           pattern: '(cat|cater|caterpillar)'
		           subject: 'caterpillar'.
	presenter := PCRE2DebuggerPresenter on: session.
	presenter runTrace.
	row := presenter tracePresenter stepsTable items second.

	presenter tracePresenter stepsTable selectItem: row.
	self
		assert: session selectedStepIndex
		equals: row representativeStep index.
	self assert: session stepStatusString equals: 'Step 2 / 6'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterUsesSession [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.
	self assert: presenter session equals: session.
	presenter runTrace.
	self assert: session hasTrace.
	self assert: session selectedStep notNil.
	self assert: session selectedStepIndex equals: 1.
	self assert: presenter tracePresenter trace equals: session trace
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testRunTraceBuildsTraceAndPersistentMatch [

	| session |
	session := PCRE2DebugSession pattern: 'c(a)t' subject: 'cat'.
	session runTrace.
	self deny: session hasError.
	self assert: session hasTrace.
	self assert: session stepCount > 0.
	self assert: session selectedStep notNil.
	self assert: session trace isMatch.
	self assert: session trace matchedString equals: 'cat'.
	self assert: session trace match offsets isArray
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testRunTraceCapturesCompileError [

	| session |
	session := PCRE2DebugSession pattern: '(' subject: 'cat'.
	session runTrace.
	self assert: session hasError.
	self deny: session hasTrace.
	self assert: session selectedStep isNil.
	self assert: (session statusString includesSubstring: 'Error:')
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterAcceptsTraceModel [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	session runTrace.
	presenter := PCRE2TracePresenter on: session trace.
	self assert: presenter trace equals: session trace.
	self assert: presenter selectedStep notNil.
	self
		assert: presenter stepsTable items size
		equals: session trace steps size
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterCanSelectEquivalentStepInsideGroup [

	| externalStep group presenter trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch:
		         'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].
	externalStep := trace steps third.

	presenter selectedStep: externalStep.
	self assert: presenter selectedRow equals: group.
	self assert: presenter selectedStep equals: externalStep.
	self assert: presenter stepsTable selectedItem equals: group
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterGroupedContextHighlightsWholeRun [

	| context excerpt group highlightInterval presenter title trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch:
		         'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].
	context := presenter
		           patternContextTextForRow: group
		           range: (presenter patternRangeForRow: group).
	title := 'Pattern 2-5 "cat|" | automatic x5'.
	excerpt := '(cat|cater|caterpillar)'.
	highlightInterval := presenter
		                     sourceContextHighlightIntervalFor:
		                     (presenter patternRangeForRow: group)
		                     contextStart: 1
		                     titleLineSize: title size
		                     excerpt: excerpt
		                     hasLeadingEllipsis: false.

	self assert: (context asString includesSubstring: title).
	self assert: (context asString includesSubstring: excerpt).
	self deny: (context asString includesSubstring: '^^^^').
	self
		assertContextText: context
		highlights: 'cat|'
		at: highlightInterval
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterGroupsLongAutomaticProgressRuns [

	| group presenter rows trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch:
		         'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	rows := presenter stepsTable items.
	group := rows detect: [ :row | row isGroup ].

	self assert: rows size < trace steps size.
	self assert: group indexLabel equals: '2-6'.
	self assert: group kindLabel equals: 'advance x5'.
	self
		assert: (presenter patternLabelForRow: group)
		equals: '2-5 "cat|"'.
	self assert: (presenter subjectLabelForRow: group) equals: '1-3'.
	self
		assert: (presenter calloutLabelForRow: group)
		equals: 'automatic x5'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterHighlightsEmptyFullSourceRangeWithoutCaretLine [

	| presenter text |
	presenter := PCRE2TracePresenter new.
	text := presenter highlightedTextFor: 'abc' range: (1 to: 0).

	self assert: text asString equals: 'abc'.
	self assertContextText: text highlights: 'a' at: (1 to: 1)
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterLabelsRowsWithPatternSnippetsAndSubjectRanges [

	| presenter row trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	row := presenter stepsTable items detect: [ :each |
		       each firstStep event number = 1 ].

	self assert: (presenter patternLabelForRow: row) equals: '6 "a"'.
	self assert: (presenter subjectLabelForRow: row) equals: 'at 1'.
	self assert: (presenter calloutLabelForRow: row) equals: '#1'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterMainPresentersHaveHelpText [

	| presenter trace widgets |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	widgets := {
		           presenter statusLabel.
		           presenter patternText.
		           presenter subjectText.
		           presenter patternContextText.
		           presenter subjectContextText.
		           presenter stepsTable.
		           presenter capturesTable.
		           presenter detailsText }.

	widgets do: [ :each |
		self deny: each help isNil.
		self deny: each help isEmpty ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterPatternContextShowsCalloutNeighborhood [

	| context excerpt highlightInterval presenter row title trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	row := presenter stepsTable items detect: [ :each |
		       each firstStep event number = 1 ].
	context := presenter
		           patternContextTextForRow: row
		           range: row firstStep patternRange.
	title := 'Pattern 6 "a" | #1'.
	excerpt := '(?C1)a(?C"step")b'.
	highlightInterval := presenter
		                     sourceContextHighlightIntervalFor:
		                     row firstStep patternRange
		                     contextStart: 1
		                     titleLineSize: title size
		                     excerpt: excerpt
		                     hasLeadingEllipsis: false.

	self assert: context asString equals: title , String cr , excerpt.
	self assertContextText: context highlights: 'a' at: highlightInterval
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterSelectingStepInsideGroupKeepsThatStep [

	| group presenter step trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch:
		         'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].
	step := group steps second.

	presenter selectedStep: step.
	self assert: presenter selectedRow equals: group.
	self assert: presenter selectedStep equals: step
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterSelectionCanUseGroupedRows [

	| group presenter trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch:
		         'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].

	presenter selectedRow: group.
	self assert: presenter selectedRow equals: group.
	self assert: presenter selectedStep equals: group representativeStep.
	self assert: presenter selectedStep index equals: 2
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterUpdatesRenderedContextPanes [

	| presenter row trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	row := presenter stepsTable items detect: [ :each |
		       each firstStep event number = 1 ].

	presenter selectedRow: row.
	self assert:
		(presenter patternContextText text asString includesSubstring:
			 '(?C1)a(?C"step")b').
	self deny:
		(presenter patternContextText text asString includesSubstring:
			 '^^^^').
	self assert:
		(presenter subjectContextText text asString includesSubstring:
			 'Subject at 1 | #1')
]
