"
I am the standalone PCRE2 pattern debugger window.

I own a PCRE2DebugSession and provide editing controls for the pattern, subject, and trace step limit. The actual trace visualization is delegated to PCRE2TracePresenter so the same UI can also be embedded in inspector tabs.
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
		'previousButton',
		'nextButton',
		'firstButton',
		'lastButton',
		'stepLabel',
		'statusLabel',
		'tracePresenter'
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

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> connectPresenters [

	runButton action: [ self runTrace ].
	firstButton action: [ self goFirstStep ].
	previousButton action: [ self goPreviousStep ].
	nextButton action: [ self goNextStep ].
	lastButton action: [ self goLastStep ].
	tracePresenter stepsTable whenSelectedItemChangedDo: [ :row |
		row ifNotNil: [
			session selectStep: row representativeStep.
			self refreshStepStatus ] ]
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> defaultLayout [

	| controls editorPane navigationRow optionsRow |
	optionsRow := SpBoxLayout newLeftToRight
		              spacing: 6;
		              add: 'Max steps' expand: false;
		              add: maximumStepsInput width: 90;
		              add: runButton width: 90;
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
		            add: navigationRow height: 32;
		            yourself.
	editorPane := SpBoxLayout newTopToBottom
		              borderWidth: 8;
		              spacing: 6;
		              add: 'Input pattern' height: 20;
		              add: patternInput height: 30;
		              add: 'Input subject' height: 20;
		              add: subjectText;
		              add: controls height: 68;
		              add: statusLabel height: 24;
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
		                     yourself.
	runButton := self newButton
		             label: 'Trace';
		             icon: (self iconNamed: #smallDoIt);
		             help:
			             'Compile the pattern and run an instrumented PCRE2 trace';
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
	statusLabel := self newLabel.
	tracePresenter := self instantiate: PCRE2TracePresenter.
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PCRE2DebuggerPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter initialExtent: 1200 @ 760
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> patternInput [

	^ patternInput
]

{ #category : 'layout' }
PCRE2DebuggerPresenter >> patternInputHelpString [

	^ 'Editable pattern for the next trace run.'
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshFromSession [

	tracePresenter trace: session trace.
	session trace ifNotNil: [
		session selectedStep ifNil: [ session firstStep ].
		session selectedStep ifNotNil: [ :step |
			tracePresenter selectedStep: step ] ].
	statusLabel label: session statusString.
	self refreshStepStatus
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> refreshStepStatus [

	stepLabel label: session stepStatusString
]

{ #category : 'actions' }
PCRE2DebuggerPresenter >> runTrace [

	session
		pattern: patternInput text;
		subject: subjectText text;
		maximumSteps: maximumStepsInput number.
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

{ #category : 'layout' }
PCRE2DebuggerPresenter >> subjectInputHelpString [

	^ 'Editable subject for the next trace run. This may differ from the traced subject until Trace is pressed.'
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> subjectText [

	^ subjectText
]

{ #category : 'accessing' }
PCRE2DebuggerPresenter >> tracePresenter [

	^ tracePresenter
]

{ #category : 'updating' }
PCRE2DebuggerPresenter >> updatePresenter [

	self refreshFromSession
]
