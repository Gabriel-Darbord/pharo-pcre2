"
I am the standalone PCRE2 pattern debugger window.

I own a PCRE2DebugSession and provide editing controls for the pattern, subject, trace display limit, trace-all execution, and live stepping. Trace-all mode records a complete instrumented match in one operation. Live controls record deterministic callout prefixes or continue the same instrumented matcher to completion, without suspending inside a native callback.

The trace visualization is delegated to PCRE2TracePresenter so the same source, timeline, capture, detail, and trace-status panes can be reused by inspector integrations.
"
Class {
	#name : 'PCRE2DebuggerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'patternInput',
		'subjectText',
		'maximumStepsInput',
		'runButton',
		'stepButton',
		'continueButton',
		'pauseButton',
		'abortButton',
		'previousButton',
		'nextButton',
		'firstButton',
		'lastButton',
		'stepLabel',
		'tracePresenter',
		'refreshingTrace'
	],
	#category : 'PCRE2-Tools-Presenters',
	#package : 'PCRE2-Tools',
	#tag : 'Presenters'
}

{ #category : 'instance creation' }
PCRE2DebuggerPresenter class >> onPattern: patternString subject: subjectString [
	"Answer a debugger on a pattern and a subject, without opening a window."

	^ self on: (PCRE2DebugSession pattern: patternString subject: subjectString)
]

{ #category : 'opening' }
PCRE2DebuggerPresenter class >> open [
	"Open the debugger with nothing in it. A pattern and a subject can be typed into the window."

	^ self openOnPattern: '' subject: ''
]

{ #category : 'opening' }
PCRE2DebuggerPresenter class >> openOnPattern: patternString [
	"Open the debugger on a pattern, leaving the subject to be typed into the window."

	^ self openOnPattern: patternString subject: ''
]

{ #category : 'opening' }
PCRE2DebuggerPresenter class >> openOnPattern: patternString subject: subjectString [
	"Open the debugger on a pattern and a subject, and answer the debugger itself rather than its window, so the caller can go on driving it."

	| presenter |
	presenter := self onPattern: patternString subject: subjectString.
	presenter open.
	^ presenter
]

{ #category : 'opening' }
PCRE2DebuggerPresenter class >> openOnSubject: subjectString [
	"Open the debugger on a subject, leaving the pattern to be typed into the window."

	^ self openOnPattern: '' subject: subjectString
]

{ #category : 'specs' }
PCRE2DebuggerPresenter class >> title [

	^ 'PCRE2 Debugger'
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> abortButton [

	^ abortButton
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> abortLiveRun [

	session abortLiveRun.
	self refreshFromSession
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> connectPresenters [

	runButton action: [ self runTrace ].
	stepButton action: [ self stepLiveRun ].
	continueButton action: [ self continueLiveRun ].
	pauseButton action: [ self pauseLiveRun ].
	abortButton action: [ self abortLiveRun ].
	firstButton action: [ self goFirstStep ].
	previousButton action: [ self goPreviousStep ].
	nextButton action: [ self goNextStep ].
	lastButton action: [ self goLastStep ].
	tracePresenter stepsTable whenSelectedItemChangedDo: [ :row |
			refreshingTrace ifFalse: [
					row ifNotNil: [
							session selectStep: row representativeStep.
							self refreshStepStatus ] ] ]
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> continueButton [

	^ continueButton
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> continueLiveRun [

	| run |
	session executionMode: #stepLive.
	self syncSessionInputs.
	session continueLiveRun.
	run := session liveRun.
	run ifNotNil: [
		run whenCompletedDo: [ :completedRun | completedRun == session liveRun ifTrue: [ self defer: [ self refreshFromSession ] ] ] ].
	self refreshFromSession
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> defaultLayout [

	| controls editorPane liveRow navigationRow optionsRow |
	optionsRow := SpBoxLayout newLeftToRight
		              spacing: 6;
		              add: 'Max steps' expand: false;
		              add: maximumStepsInput width: 90;
		              add: runButton expand: false;
		              yourself.
	liveRow := SpBoxLayout newLeftToRight
		           spacing: 6;
		           add: stepButton;
		           add: continueButton;
		           add: pauseButton;
		           add: abortButton;
		           yourself.
	navigationRow := SpBoxLayout newLeftToRight
		                 spacing: 6;
		                 add: firstButton width: 40;
		                 add: previousButton width: 40;
		                 add: stepLabel;
		                 add: nextButton width: 40;
		                 add: lastButton width: 40;
		                 yourself.
	controls := SpBoxLayout newTopToBottom
		            spacing: 6;
		            add: optionsRow expand: false;
		            add: liveRow expand: false;
		            add: navigationRow expand: false;
		            yourself.
	editorPane := SpBoxLayout newTopToBottom
		              borderWidth: 8;
		              spacing: 6;
		              add: 'Input pattern' expand: false;
		              add: patternInput;
		              add: 'Input subject' expand: false;
		              add: subjectText;
		              add: controls expand: false;
		              yourself.
	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 35 percent;
		  add: editorPane;
		  add: tracePresenter;
		  yourself
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> firstButton [

	^ firstButton
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> goFirstStep [

	session firstStep.
	self selectSessionStepInTracePresenter
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> goLastStep [

	session lastStep.
	self selectSessionStepInTracePresenter
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> goNextStep [

	session nextStep.
	self selectSessionStepInTracePresenter
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> goPreviousStep [

	session previousStep.
	self selectSessionStepInTracePresenter
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> initialize [

	super initialize.
	refreshingTrace := false
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> initializePresenters [

	session ifNil: [ session := PCRE2DebugSession new ].
	patternInput := self newText
		                beWrapWord;
		                withScrollBars;
		                text: session pattern;
		                help: self patternInputHelpString;
		                yourself.
	subjectText := self newText
		               text: session subject;
		               help: self subjectInputHelpString;
		               yourself.
	maximumStepsInput := self newNumberInput
		                     beInteger;
		                     rangeMinimum: 1 maximum: 100000;
		                     number: session maximumSteps;
		                     help: 'Maximum trace rows to display.';
		                     yourself.
	runButton := self newButton
		             label: 'Trace all';
		             icon: (self iconNamed: #smallDoIt);
		             help: 'Compile the pattern and record a complete instrumented trace.';
		             yourself.
	stepButton := self newButton
		              label: 'Step';
		              help: 'Start or advance live execution to the next callout.';
		              yourself.
	continueButton := self newButton
		                  label: 'Continue';
		                  help: 'Resume live execution without stopping at later callouts.';
		                  yourself.
	pauseButton := self newButton
		               label: 'Pause';
		               help: 'Pause live execution at the next callout.';
		               yourself.
	abortButton := self newButton
		               label: 'Abort';
		               help: 'Stop the current live execution.';
		               yourself.
	firstButton := self newButton
		               label: '|<';
		               help: 'First step';
		               yourself.
	previousButton := self newButton
		                  label: '<';
		                  help: 'Previous step';
		                  yourself.
	nextButton := self newButton
		              label: '>';
		              help: 'Next step';
		              yourself.
	lastButton := self newButton
		              label: '>|';
		              help: 'Last step';
		              yourself.
	stepLabel := self newLabel.
	tracePresenter := self instantiate: PCRE2TracePresenter.
	self refreshModeControls.
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: self class title;
		windowIcon: (self iconNamed: #smallFind);
		initialExtent: 1200 @ 720
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> lastButton [

	^ lastButton
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> maximumStepsInput [

	^ maximumStepsInput
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> nextButton [

	^ nextButton
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> patternInput [

	^ patternInput
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> patternInputHelpString [

	^ 'Editable pattern for the next debugger run.'
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> pauseButton [

	^ pauseButton
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> pauseLiveRun [

	session pauseLiveRun.
	self refreshFromSession
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> previousButton [

	^ previousButton
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshFromSession [

	session executionMode = #stepLive ifTrue: [ session refreshLiveTrace ].
	refreshingTrace := true.
	[
		tracePresenter trace: session trace.
		session hasError ifTrue: [ tracePresenter statusLabel label: session statusString ].
		session trace ifNotNil: [
				session selectedStep ifNil: [ session firstStep ].
				session selectedStep ifNotNil: [ :step | tracePresenter selectedStep: step ] ] ] ensure: [ refreshingTrace := false ].
	self refreshStepStatus.
	self refreshModeControls
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshModeControls [
	"Enable only what can be done right now: starting a run needs no run in flight, pausing needs one, aborting needs one that has not ended, and walking the trace needs a trace to walk."

	| liveRun running hasSteps |
	liveRun := session liveRun.
	running := session liveRunState = #running.
	hasSteps := session stepCount > 0.
	runButton enabled: running not.
	stepButton enabled: running not.
	continueButton enabled: running not.
	pauseButton enabled: running.
	abortButton enabled: (liveRun isNotNil and: [ liveRun isFinished not ]).
	{
		firstButton.
		previousButton.
		nextButton.
		lastButton } do: [ :button | button enabled: hasSteps ]
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshStepStatus [

	stepLabel label: session stepStatusString
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> runButton [

	^ runButton
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> runTrace [

	session executionMode: #traceAll.
	self syncSessionInputs.
	session runTrace.
	self refreshFromSession
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> selectSessionStepInTracePresenter [

	session selectedStep ifNotNil: [ :step |
			refreshingTrace := true.
			[ tracePresenter selectedStep: step ] ensure: [ refreshingTrace := false ] ].
	self refreshStepStatus
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> session [

	^ session
]

{ #category : 'accessing - model' }
PCRE2DebuggerPresenter >> setModelBeforeInitialization: aPCRE2DebugSession [

	session := aPCRE2DebugSession
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> stepButton [

	^ stepButton
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> stepLabel [

	^ stepLabel
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> stepLiveRun [

	session executionMode: #stepLive.
	self syncSessionInputs.
	session stepLiveRun.
	self refreshFromSession
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> subjectInputHelpString [

	^ 'Editable subject for the next debugger run. This may differ from the traced subject until a run starts.'
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> subjectText [

	^ subjectText
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> syncSessionInputs [

	session pattern: patternInput text subject: subjectText text maximumSteps: maximumStepsInput number
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> tracePresenter [

	^ tracePresenter
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> updatePresenter [

	self refreshFromSession
]
