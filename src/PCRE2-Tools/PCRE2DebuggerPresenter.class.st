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

{ #category : 'opening' }
PCRE2DebuggerPresenter class >> openOnPattern: patternString subject: subjectString [

	^ (self on:
		   (PCRE2DebugSession pattern: patternString subject: subjectString))
		  open
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
		run whenCompletedDo: [ :completedRun |
			completedRun == session liveRun ifTrue: [
				self defer: [ self refreshFromSession ] ] ] ].
	self refreshFromSession
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> defaultLayout [

	| controls editorPane liveRow navigationRow optionsRow |
	optionsRow := SpBoxLayout newLeftToRight
		              spacing: 6;
		              add: 'Max steps' expand: false;
		              add: maximumStepsInput width: 90;
		              add: runButton width: 120;
		              yourself.
	liveRow := SpBoxLayout newLeftToRight
		           spacing: 6;
		           add: stepButton width: 80;
		           add: continueButton width: 100;
		           add: pauseButton width: 80;
		           add: abortButton width: 80;
		           yourself.
	navigationRow := SpBoxLayout newLeftToRight
		                 spacing: 6;
		                 add: firstButton width: 36;
		                 add: previousButton width: 36;
		                 add: stepLabel;
		                 add: nextButton width: 36;
		                 add: lastButton width: 36;
		                 yourself.
	controls := SpBoxLayout newTopToBottom
		            spacing: 4;
		            add: optionsRow height: 32;
		            add: liveRow height: 32;
		            add: navigationRow height: 32;
		            yourself.
	editorPane := SpBoxLayout newTopToBottom
		              borderWidth: 8;
		              spacing: 6;
		              add: 'Input pattern' height: 20;
		              add: patternInput height: 30;
		              add: 'Input subject' height: 20;
		              add: subjectText;
		              add: controls height: 104;
		              yourself.
	^ SpPanedLayout newLeftToRight
		  positionOfSlider: 35 percent;
		  add: editorPane;
		  add: tracePresenter;
		  yourself
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

	refreshingTrace := false.
	super initialize
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> initializePresenters [

	session ifNil: [ session := PCRE2DebugSession new ].
	patternInput := self newTextInput
		                text: session pattern;
		                placeholder: 'Pattern';
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
		             help:
			             'Compile the pattern and record a complete instrumented trace.';
		             yourself.
	stepButton := self newButton
		              label: 'Step';
		              help:
			              'Start or advance live execution to the next callout.';
		              yourself.
	continueButton := self newButton
		                  label: 'Continue';
		                  help:
			                  'Resume live execution without stopping at later callouts.';
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
		initialExtent: 1200 @ 680;
		initialPosition: 20 @ 40
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

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshFromSession [

	session executionMode = #stepLive ifTrue: [ session refreshLiveTrace ].
	refreshingTrace := true.
	[
	tracePresenter trace: session trace.
	session hasError ifTrue: [
		tracePresenter statusLabel label: session statusString ].
	session trace ifNotNil: [
		session selectedStep ifNil: [ session firstStep ].
		session selectedStep ifNotNil: [ :step |
			tracePresenter selectedStep: step ] ] ] ensure: [
		refreshingTrace := false ].
	self refreshStepStatus.
	self refreshModeControls
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshModeControls [

	{
		runButton.
		stepButton.
		continueButton.
		pauseButton.
		abortButton.
		firstButton.
		previousButton.
		nextButton.
		lastButton } do: [ :button |
		button ifNotNil: [ button enabled: true ] ].
	^ self
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshStepStatus [

	stepLabel label: session stepStatusString
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
		tracePresenter selectedStep: step ].
	self refreshStepStatus
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> session [

	^ session
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> setModelBeforeInitialization: aPCRE2DebugSession [

	session := aPCRE2DebugSession
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> stepButton [

	^ stepButton
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

	session
		pattern: patternInput text
		subject: subjectText text
		maximumSteps: maximumStepsInput number.
	^ self
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> tracePresenter [

	^ tracePresenter
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> updatePresenter [

	self refreshFromSession
]
