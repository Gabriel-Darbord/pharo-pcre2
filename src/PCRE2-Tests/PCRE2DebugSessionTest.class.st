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
	self
		assert: (presenter subjectLabelForRow: group)
		equals: '1-3 "cat"'.
	self
		assert: (presenter calloutLabelForRow: group)
		equals: 'automatic x5'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterLabelsSingleRowsWithSourceSnippets [

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
