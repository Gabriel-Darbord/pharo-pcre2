"
Tests for the PCRE2-Tools debugger session and presenter wiring.

I am abstract: every case here runs once per loaded backend, through a subclass that pins one. The tools only ever use the public PCRE2 protocol, so the same cases must hold whichever implementation compiled the pattern.

These tests stay headless: they verify the model and presenter objects without opening Morphic windows.
"
Class {
	#name : 'PCRE2DebugSessionTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tools-Tests-Debugging',
	#package : 'PCRE2-Tools-Tests',
	#tag : 'Debugging'
}

{ #category : 'testing' }
PCRE2DebugSessionTest class >> backendClass [
	"Answer the compiler backend the cases run on. Each subclass lives in a package that requires the backend it names."

	^ self subclassResponsibility
]

{ #category : 'testing' }
PCRE2DebugSessionTest class >> isAbstract [
	"The cases here are run by the subclasses that pin a backend, not by me."

	^ self == PCRE2DebugSessionTest
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> assertContextText: aText highlights: expectedSubstring at: highlightInterval [

	| attributes |
	self assert: (aText asString copyFrom: highlightInterval first to: highlightInterval last) equals: expectedSubstring.
	attributes := aText attributesAt: highlightInterval first.
	self assert: (attributes anySatisfy: [ :each | each isKindOf: TextColor ]).
	self assert: (attributes anySatisfy: [ :each | each isKindOf: TextBackgroundColor ])
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> emptyTraceRecorder [
	"Answer a recorder that has seen nothing yet, for testing how it answers questions as events arrive."

	^ PCRE2TraceRecorder
		  pattern: 'ab'
		  patternInput: nil
		  subject: 'ab'
		  input: nil
		  calloutSites: #(  )
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> highlightedIndexesOf: aText [
	"Answer the character positions aText gives a background colour to."

	^ (1 to: aText size) select: [ :index |
		  (aText attributesAt: index) anySatisfy: [ :attribute | attribute isKindOf: TextBackgroundColor ] ]
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> layOut: aPresenter in: anExtent [
	"Build aPresenter's widget at this size and settle its layout, so the test can read where things ended up without opening a window."

	| morph |
	morph := aPresenter build.
	morph extent: anExtent.
	morph fullBounds.
	^ morph
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> liveSessionOn: patternString subject: subjectString do: aBlock [
	"Evaluate aBlock with a session in live-stepping mode, and stop the run afterwards whatever happens."

	| session |
	session := PCRE2DebugSession pattern: patternString subject: subjectString.
	session executionMode: #stepLive.
	^ [ aBlock value: session ] ensure: [ session abortLiveRun ]
]

{ #category : 'helpers' }
PCRE2DebugSessionTest >> navigationButtonsOf: aDebuggerPresenter do: aBlock [
	"Evaluate aBlock with each of the four buttons that walk a recorded trace."

	{
		aDebuggerPresenter firstButton.
		aDebuggerPresenter previousButton.
		aDebuggerPresenter nextButton.
		aDebuggerPresenter lastButton } do: aBlock
]

{ #category : 'running' }
PCRE2DebugSessionTest >> runCase [
	"Run every case on the backend this class pins, whatever the image default is, so the debugger is covered once per implementation."

	^ PCRE2Compiler withDefaultBackend: self class backendClass do: [ super runCase ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testBackendAnswersWhichCodeUnitWidthsItSupports [

	| backend |
	backend := self class backendClass.
	self assert: (PCRE2Compiler supportsCodeUnitWidth: 8).
	self deny: (PCRE2Compiler supportsCodeUnitWidth: 7).
	#( 8 16 32 ) do: [ :width |
		self assert: (PCRE2Compiler supportsCodeUnitWidth: width) equals: (backend supportsCodeUnitWidth: width) ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebugSessionCanTraceWithUTF16Compiler [

	| session |
	(PCRE2Compiler supportsCodeUnitWidth: 16) ifFalse: [ self skip ].

	session := PCRE2DebugSession pattern: 'é' subject: 'é' compiler: PCRE2UTF16Compiler.
	session runTrace.

	self deny: session hasError.
	self assert: session matcher class equals: PCRE2UTF16Matcher.
	self assert: session trace input class equals: PCRE2UTF16Input.
	self assert: session trace matchedString equals: 'é'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebugSessionCanTraceWithUTF32Compiler [

	| session |
	(PCRE2Compiler supportsCodeUnitWidth: 32) ifFalse: [ self skip ].

	session := PCRE2DebugSession pattern: 'é' subject: 'é' compiler: PCRE2UTF32Compiler.
	session runTrace.

	self deny: session hasError.
	self assert: session matcher class equals: PCRE2UTF32Matcher.
	self assert: session trace input class equals: PCRE2UTF32Input.
	self assert: session trace matchedString equals: 'é'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebugSessionSelectStepUsesStableStepIndex [

	| externalStep session |
	session := PCRE2DebugSession pattern: '(cat|cater|caterpillar)' subject: 'caterpillar'.
	session runTrace.
	externalStep := session trace steps second.

	session selectStep: externalStep.
	self assert: session selectedStepIndex equals: externalStep index.
	self assert: session selectedStep index equals: externalStep index
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebugSessionStepLiveRunSelectsNewestRecordedStep [

	| session |
	session := PCRE2DebugSession pattern: 'ab' subject: 'ab'.
	[
		session executionMode: #stepLive.
		session stepLiveRun.
		self assert: session liveRun isPaused.
		self assert: session stepCount equals: 1.
		session stepLiveRun.
		self assert: session liveRun isPaused.
		self assert: session stepCount > 1.
		self assert: session selectedStepIndex equals: session stepCount ] ensure: [ session abortLiveRun ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerCanBeBuiltFromEveryEntryPoint [
	"Each way in builds a session with the pattern and subject it was given, and nothing it was not."

	self assert: (PCRE2DebuggerPresenter onPattern: '' subject: '') session pattern equals: ''.
	self assert: (PCRE2DebuggerPresenter onPattern: 'ab' subject: '') session pattern equals: 'ab'.
	self assert: (PCRE2DebuggerPresenter onPattern: 'ab' subject: '') session subject equals: ''.
	self assert: (PCRE2DebuggerPresenter onPattern: '' subject: 'cd') session subject equals: 'cd'.
	self assert: (PCRE2DebuggerPresenter onPattern: 'ab' subject: 'cd') session subject equals: 'cd'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerControlsFitInsideItsWindow [
	"The row of trace-navigation buttons is the last thing in the editor column, and it has to fit: a button laid out at its natural height rather than its row's pushed it past the bottom of the window."

	| bottom presenter |
	presenter := PCRE2DebuggerPresenter onPattern: '(cat|cater)' subject: 'cater'.
	bottom := (self layOut: presenter in: 1200 @ 720) bounds bottom.

	{
		presenter firstButton.
		presenter lastButton.
		presenter stepButton.
		presenter runButton } do: [ :button | self assert: button adapter widget bounds bottom <= bottom ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPatternInputWrapsAndScrollsAsMultilineText [

	| presenter session |
	session := PCRE2DebugSession pattern: 'first line second line' subject: 'subject'.
	presenter := PCRE2DebuggerPresenter on: session.

	self assert: presenter patternInput isWrapWord.
	self assert: presenter patternInput hasScrollBars.
	self assert: presenter patternInput text asString equals: session pattern
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterEnablesOnlyWhatCanBeDoneWithoutATrace [

	| presenter |
	presenter := PCRE2DebuggerPresenter onPattern: 'ab' subject: 'ab'.
	self assert: presenter runButton isEnabled.
	self assert: presenter stepButton isEnabled.
	self assert: presenter continueButton isEnabled.
	self deny: presenter pauseButton isEnabled.
	self deny: presenter abortButton isEnabled.
	self navigationButtonsOf: presenter do: [ :button | self deny: button isEnabled ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterEnablesTraceNavigationOnceThereIsATrace [

	| presenter |
	presenter := PCRE2DebuggerPresenter onPattern: '(cat|cater)' subject: 'cater'.
	presenter runTrace.
	self assert: presenter session stepCount > 0.
	self navigationButtonsOf: presenter do: [ :button | self assert: button isEnabled ].
	self deny: presenter pauseButton isEnabled.
	self deny: presenter abortButton isEnabled
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterInputsHaveHelpText [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.

	self assert: presenter patternInput help equals: presenter patternInputHelpString.
	self assert: presenter subjectText help equals: presenter subjectInputHelpString
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterLastStepSelectsConcreteLastStepInsideGroupedRow [

	| presenter session |
	session := PCRE2DebugSession pattern: '(cat|cater|caterpillar)' subject: 'caterpillar'.
	presenter := PCRE2DebuggerPresenter on: session.
	presenter runTrace.

	presenter goLastStep.
	self assert: presenter tracePresenter selectedRow isGroup.
	self assert: session selectedStepIndex equals: session stepCount.
	self assert: presenter tracePresenter selectedStep index equals: session stepCount.
	self assert: presenter tracePresenter selectedRow lastStep index equals: session stepCount
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterLiveControlsUseTracePresenter [

	| presenter session |
	session := PCRE2DebugSession pattern: 'ab' subject: 'ab'.
	presenter := PCRE2DebuggerPresenter on: session.
	[
		presenter stepLiveRun.
		self assert: session executionMode equals: #stepLive.
		self assert: session hasTrace.
		self assert: presenter tracePresenter trace equals: session trace.
		self assert: presenter tracePresenter selectedStep index equals: session selectedStep index.
		self deny: presenter stepButton help isEmpty.
		self deny: presenter continueButton help isEmpty.
		self deny: presenter pauseButton help isEmpty.
		self deny: presenter abortButton help isEmpty ] ensure: [ session abortLiveRun ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterOpensWithNoPatternOrSubject [

	| presenter |
	presenter := PCRE2DebuggerPresenter onPattern: '' subject: ''.
	self assert: presenter session pattern equals: ''.
	self assert: presenter session subject equals: ''.
	self assert: presenter patternInput text equals: ''.
	self assert: presenter subjectText text equals: ''.
	self deny: presenter session hasTrace.
	self assert: presenter session stepCount equals: 0.
	self assert: presenter session statusString equals: 'No trace yet.'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterRefreshPreservesSelectedTraceRow [

	| presenter row session |
	session := PCRE2DebugSession pattern: '(cat|cater|caterpillar)' subject: 'caterpillar'.
	presenter := PCRE2DebuggerPresenter on: session.
	presenter runTrace.
	row := presenter tracePresenter stepsTable items second.
	presenter tracePresenter stepsTable selectItem: row.
	self assert: session selectedStepIndex equals: row representativeStep index.

	presenter refreshFromSession.
	self assert: presenter tracePresenter selectedStep index equals: row representativeStep index.
	self assert: session selectedStepIndex equals: row representativeStep index
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterRowSelectionUpdatesSessionStepIndex [

	| presenter row session |
	session := PCRE2DebugSession pattern: '(cat|cater|caterpillar)' subject: 'caterpillar'.
	presenter := PCRE2DebuggerPresenter on: session.
	presenter runTrace.
	row := presenter tracePresenter stepsTable items second.

	presenter tracePresenter stepsTable selectItem: row.
	self assert: session selectedStepIndex equals: row representativeStep index.
	self assert: session stepStatusString equals: 'Step 2 / 6'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterShowsCompileErrorsInTraceStatus [

	| presenter session |
	session := PCRE2DebugSession pattern: '(' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.

	presenter runTrace.

	self assert: session hasError.
	self assert: (presenter tracePresenter statusLabel label includesSubstring: 'Error:')
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterUsesSession [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	presenter := PCRE2DebuggerPresenter on: session.
	self assert: presenter session equals: session.
	presenter runTrace.
	self assert: session hasTrace.
	self assert: session selectedStep isNotNil.
	self assert: session selectedStepIndex equals: 1.
	self assert: presenter tracePresenter trace equals: session trace
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testDebuggerPresenterWindowCarriesATitle [

	| presenter |
	presenter := PCRE2DebuggerPresenter onPattern: 'ab' subject: 'ab'.
	self assert: presenter asWindow title equals: PCRE2DebuggerPresenter title.
	self assert: PCRE2DebuggerPresenter title equals: 'PCRE2 Debugger'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunCanUseUTF16Compiler [

	| run |
	(PCRE2Compiler supportsCodeUnitWidth: 16) ifFalse: [ self skip ].

	run := PCRE2LiveDebugRun pattern: 'é' subject: 'é' compiler: PCRE2UTF16Compiler.
	[
		run startContinuing.
		self assert: (run waitForCompletionMilliseconds: 1000).
		self assert: run matcher class equals: PCRE2UTF16Matcher.
		self assert: run recorder isMatch.
		self assert: run recorder matchedString equals: 'é' ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunCanUseUTF32Compiler [

	| run |
	(PCRE2Compiler supportsCodeUnitWidth: 32) ifFalse: [ self skip ].

	run := PCRE2LiveDebugRun pattern: 'é' subject: 'é' compiler: PCRE2UTF32Compiler.
	[
		run startContinuing.
		self assert: (run waitForCompletionMilliseconds: 1000).
		self assert: run matcher class equals: PCRE2UTF32Matcher.
		self assert: run recorder isMatch.
		self assert: run recorder matchedString equals: 'é' ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunCompletionCallbackFiresWhenContinueFinishes [

	| callbackRun callbackSemaphore run |
	callbackSemaphore := Semaphore new.
	run := PCRE2LiveDebugRun pattern: 'ab' subject: 'ab'.
	[
		run start.
		self assert: (run waitForPauseOrFinishMilliseconds: 1000).
		run whenCompletedDo: [ :completedRun |
				callbackRun := completedRun.
				callbackSemaphore signal ].
		run continue.
		self assert: (run waitForCompletionMilliseconds: 1000).
		self deny: (callbackSemaphore waitTimeoutMilliseconds: 1000).
		self assert: callbackRun equals: run.
		self assert: run runState equals: #completed ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunCompletionCallbackRunsImmediatelyWhenAlreadyFinished [

	| callbackRun run |
	run := PCRE2LiveDebugRun pattern: 'ab' subject: 'ab'.
	[
		run startContinuing.
		self assert: (run waitForCompletionMilliseconds: 1000).
		run whenCompletedDo: [ :completedRun | callbackRun := completedRun ].
		self assert: callbackRun equals: run ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunContinueCompletes [

	| run |
	run := PCRE2LiveDebugRun pattern: 'ab' subject: 'ab'.
	[
		run start.
		self assert: (run waitForPauseOrFinishMilliseconds: 1000).
		run continue.
		self assert: (run waitForCompletionMilliseconds: 1000).
		self assert: run runState equals: #completed.
		self assert: run recorder isFinished.
		self assert: run recorder isMatch.
		self assert: run recorder matchedString equals: 'ab' ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunStartsPausedAtFirstCallout [

	| run |
	run := PCRE2LiveDebugRun pattern: 'ab' subject: 'ab'.
	[
		run start.
		self assert: (run waitForPauseOrFinishMilliseconds: 1000).
		self assert: run isPaused.
		self assert: run recorder events size equals: 1 ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testLiveDebugRunStepAdvancesOneCallout [

	| firstEventCount run |
	run := PCRE2LiveDebugRun pattern: 'ab' subject: 'ab'.
	[
		run start.
		self assert: (run waitForPauseOrFinishMilliseconds: 1000).
		firstEventCount := run recorder events size.
		run step.
		self assert: (run waitForPauseOrFinishMilliseconds: 1000).
		self assert: run isPaused.
		self assert: run recorder events size > firstEventCount ] ensure: [
			run abort.
			run waitForCompletionMilliseconds: 1000 ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testRunTraceBuildsTraceAndPersistentMatch [

	| session |
	session := PCRE2DebugSession pattern: 'c(a)t' subject: 'cat'.
	session runTrace.
	self deny: session hasError.
	self assert: session hasTrace.
	self assert: session stepCount > 0.
	self assert: session selectedStep isNotNil.
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
PCRE2DebugSessionTest >> testStepCountFollowsMaximumStepsWithoutBuildingEveryStep [

	| session |
	session := PCRE2DebugSession pattern: '(cat|cater|caterpillar)' subject: 'caterpillar'.
	session runTrace.
	self assert: session stepCount equals: session steps size.
	self assert: session stepCount equals: session trace eventCount.
	self deny: session traceWasLimited.

	session maximumSteps: 3.
	self assert: session stepCount equals: 3.
	self assert: session steps size equals: 3.
	self assert: session traceWasLimited
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceCaptureRowDisplaysUnsetEmptyAndOrdinaryRanges [

	| empty ordinary unset |
	unset := PCRE2TraceCaptureRow index: 1 range: nil text: nil.
	empty := PCRE2TraceCaptureRow index: 2 range: (3 to: 2) text: ''.
	ordinary := PCRE2TraceCaptureRow index: 0 range: (1 to: 3) text: 'cat'.

	self assert: unset displayIndex equals: '1'.
	self assert: unset displayRange equals: 'unset'.
	self assert: unset text equals: ''.
	self assert: empty displayRange equals: '3 (empty)'.
	self assert: ordinary displayIndex equals: 'Full'.
	self assert: ordinary displayRange equals: '1-3'.
	self assert: ordinary text equals: 'cat'
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterAcceptsTraceModel [

	| presenter session |
	session := PCRE2DebugSession pattern: 'cat' subject: 'cat'.
	session runTrace.
	presenter := PCRE2TracePresenter on: session trace.
	self assert: presenter trace equals: session trace.
	self assert: presenter selectedStep isNotNil.
	self assert: presenter stepsTable items size equals: session trace steps size
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterCanSelectEquivalentStepInsideGroup [

	| externalStep group presenter trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].
	externalStep := trace steps third.

	presenter selectedStep: externalStep.
	self assert: presenter selectedRow equals: group.
	self assert: presenter selectedStep equals: externalStep.
	self assert: presenter stepsTable selectedItem equals: group
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterContextEllipsesUseMetaColor [

	| callout context excerptStart presenter source title titleLine trailingStart |
	presenter := PCRE2TracePresenter new.
	source := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.
	title := 'Pattern 40-42'.
	callout := 'automatic'.
	titleLine := String streamContents: [ :stream | stream << title << ' | ' << callout ].
	context := presenter
		           sourceContextTextFor: source
		           range: (40 to: 42)
		           title: title
		           callout: callout.
	excerptStart := titleLine size + 2.
	trailingStart := context size - 2.

	self assert: (context asString copyFrom: excerptStart to: excerptStart + 2) equals: '...'.
	self assert: (context asString copyFrom: trailingStart to: context size) equals: '...'.
	self assert: ((context attributesAt: excerptStart) includes: TextColor gray).
	self assert: ((context attributesAt: trailingStart) includes: TextColor gray)
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterFullSourcePanesHighlightSelectedRanges [

	| presenter row trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	row := presenter stepsTable items detect: [ :each | each firstStep event number = 1 ].

	presenter selectedRow: row.
	self assertContextText: presenter patternText text highlights: 'a' at: (6 to: 6).
	self assertContextText: presenter subjectText text highlights: 'a' at: (1 to: 1)
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterGroupedContextHighlightsWholeRun [

	| context excerpt group highlightInterval presenter title trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	group := presenter stepsTable items detect: [ :row | row isGroup ].
	context := presenter patternContextTextForRow: group range: (presenter patternRangeForRow: group).
	title := 'Pattern 2-5 "cat|" | automatic x5'.
	excerpt := '(cat|cater|caterpillar)'.
	highlightInterval := presenter
		                     sourceContextHighlightIntervalFor: (presenter patternRangeForRow: group)
		                     contextStart: 1
		                     titleLineSize: title size
		                     excerpt: excerpt
		                     hasLeadingEllipsis: false.

	self assert: (context asString includesSubstring: title).
	self assert: (context asString includesSubstring: excerpt).
	self deny: (context asString includesSubstring: '^^^^').
	self assertContextText: context highlights: 'cat|' at: highlightInterval
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterGroupsLongAutomaticProgressRuns [

	| group presenter rows trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	rows := presenter stepsTable items.
	group := rows detect: [ :row | row isGroup ].

	self assert: rows size < trace steps size.
	self assert: group indexLabel equals: '2-6'.
	self assert: group kindLabel equals: 'advance x5'.
	self assert: (presenter patternLabelForRow: group) equals: '2-5 "cat|"'.
	self assert: (presenter subjectLabelForRow: group) equals: '1-3'.
	self assert: (presenter calloutLabelForRow: group) equals: 'automatic x5'
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
	row := presenter stepsTable items detect: [ :each | each firstStep event number = 1 ].

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
PCRE2DebugSessionTest >> testTracePresenterMovesTheRenderedHighlightWhenAnotherStepIsSelected [
	"From one step to the next the traced pattern keeps the same characters and changes only its highlighting. This asserts on the text the widget ended up holding rather than on the text the presenter was handed, because a widget given a text equal to the one it already has redraws nothing, and then the first step's highlighting would stay on screen for the whole trace."

	| atFirst atLast presenter steps textMorph |
	presenter := PCRE2TracePresenter on: ('(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar').
	presenter build.
	steps := presenter trace steps.
	textMorph := presenter patternText adapter widget textMorph.

	presenter selectedStep: steps first.
	atFirst := self highlightedIndexesOf: textMorph text.
	presenter selectedStep: steps last.
	atLast := self highlightedIndexesOf: textMorph text.

	self deny: atFirst isEmpty.
	self deny: atLast isEmpty.
	self deny: atFirst equals: atLast
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterPatternContextShowsCalloutNeighborhood [

	| context excerpt highlightInterval presenter row title trace |
	trace := '(?C1)a(?C"step")b' asPerlCompatibleRegex traceMatch: 'ab'.
	presenter := PCRE2TracePresenter on: trace.
	row := presenter stepsTable items detect: [ :each | each firstStep event number = 1 ].
	context := presenter patternContextTextForRow: row range: row firstStep patternRange.
	title := 'Pattern 6 "a" | #1'.
	excerpt := '(?C1)a(?C"step")b'.
	highlightInterval := presenter
		                     sourceContextHighlightIntervalFor: row firstStep patternRange
		                     contextStart: 1
		                     titleLineSize: title size
		                     excerpt: excerpt
		                     hasLeadingEllipsis: false.

	self assert: context asString equals: title , String cr , excerpt.
	self assertContextText: context highlights: 'a' at: highlightInterval
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterRefreshPreservesSelectedStep [

	| presenter selectedStep trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
	presenter := PCRE2TracePresenter on: trace.
	selectedStep := trace steps third.
	presenter selectedStep: selectedStep.

	presenter trace: trace.
	self assert: presenter selectedStep index equals: selectedStep index
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterRowsFillTheWidthOfTheirPane [
	"Every row of the trace pane reaches the same right edge. A child given a fixed width or height in a box is laid out at its natural size on the other axis too, which used to leave the right of the pane empty."

	| presenter rightEdge statusRight |
	presenter := PCRE2TracePresenter on: ('(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar').
	self layOut: presenter in: 1000 @ 700.
	rightEdge := [ :aPresenter | aPresenter adapter widget bounds right ].
	statusRight := rightEdge value: presenter statusLabel.

	self assert: (rightEdge value: presenter subjectText) equals: statusRight.
	self assert: (rightEdge value: presenter subjectContextText) equals: statusRight.
	self assert: (rightEdge value: presenter capturesTable) equals: statusRight.
	self assert: (rightEdge value: presenter detailsText) equals: statusRight
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTracePresenterSelectingStepInsideGroupKeepsThatStep [

	| group presenter step trace |
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
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
	trace := '(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar'.
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
	row := presenter stepsTable items detect: [ :each | each firstStep event number = 1 ].

	presenter selectedRow: row.
	self assert: (presenter patternContextText text asString includesSubstring: '(?C1)a(?C"step")b').
	self deny: (presenter patternContextText text asString includesSubstring: '^^^^').
	self assert: (presenter subjectContextText text asString includesSubstring: 'Subject at 1 | #1')
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceRecorderDropsItsSnapshotWhenTheRunEnds [

	| recorder snapshot |
	recorder := self emptyTraceRecorder.
	snapshot := recorder asTrace.
	self deny: recorder isFinished.

	recorder finishWithMatch: nil resultCode: PCRE2 errorNoMatch.
	self assert: recorder isFinished.
	self deny: recorder asTrace identicalTo: snapshot.
	self assert: recorder asTrace resultCode equals: PCRE2 errorNoMatch
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceRecorderEventCountAgreesWithItsEvents [

	| recorder |
	self liveSessionOn: 'ab' subject: 'ab' do: [ :session |
			session continueLiveRun.
			session waitForLiveCompletionMilliseconds: 1000.
			recorder := session liveRun recorder.
			self assert: recorder isFinished.
			self assert: recorder eventCount equals: recorder events size.
			self assert: recorder eventCount equals: recorder asTrace eventCount.
			self assert: recorder asTrace matchedString equals: 'ab' ]
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceRecorderKeepsOneSnapshotBetweenEvents [

	| event recorder snapshot |
	event := ('ab' asPerlCompatibleRegex traceMatch: 'ab') events first.
	recorder := self emptyTraceRecorder.
	snapshot := recorder asTrace.
	self assert: recorder asTrace identicalTo: snapshot.
	self assert: recorder eventCount equals: 0.

	recorder appendEvent: event.
	self deny: recorder asTrace identicalTo: snapshot.
	self assert: recorder eventCount equals: 1.
	self assert: recorder asTrace events first identicalTo: event.
	self assert: recorder asTrace identicalTo: recorder asTrace
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceStepRowLabelsSingleAndGroupedSteps [

	| group single steps |
	steps := ('(cat|cater|caterpillar)' asPerlCompatibleRegex traceMatch: 'caterpillar') steps.
	single := PCRE2TraceStepRow steps: { steps first }.
	group := PCRE2TraceStepRow steps: (steps first: 3).

	self deny: single isGroup.
	self assert: single size equals: 1.
	self assert: single indexLabel equals: '1'.
	self assert: single representativeStep identicalTo: steps first.
	self assert: single lastStep identicalTo: steps first.

	self assert: group isGroup.
	self assert: group size equals: 3.
	self assert: group indexLabel equals: '1-3'.
	self assert: (group includesStep: (steps at: 2)).
	self deny: (group includesStep: (steps at: 4)).
	self assert: (group stepMatching: (steps at: 2) ifAbsent: [ nil ]) index equals: 2.
	self assert: (group stepMatching: (steps at: 4) ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
PCRE2DebugSessionTest >> testTraceStepRowRefusesToHoldNoStep [

	self should: [ PCRE2TraceStepRow steps: #(  ) ] raise: Error
]
