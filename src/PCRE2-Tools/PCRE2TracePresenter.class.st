"
I present a PCRE2MatchTrace.

I am designed as a reusable subpresenter: inspector extensions can embed me for an existing trace, and the standalone debugger can reuse me as its trace pane. I show a timeline of trace steps, highlighted pattern and subject text for the selected step, capture ranges, and raw event details.
"
Class {
	#name : 'PCRE2TracePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'trace',
		'stepsTable',
		'patternText',
		'subjectText',
		'capturesTable',
		'detailsText',
		'statusLabel',
		'selectedStep'
	],
	#category : 'PCRE2-Tools-Presenters',
	#package : 'PCRE2-Tools',
	#tag : 'Presenters'
}

{ #category : 'specs' }
PCRE2TracePresenter class >> title [

	^ 'PCRE2 Trace'
]

{ #category : 'display' }
PCRE2TracePresenter >> captureRowsForStep: aTraceStep [

	| rows subjectString |
	subjectString := trace subject asString.
	rows := OrderedCollection new.
	1 to: aTraceStep captureRanges size do: [ :storageIndex |
		| range |
		range := aTraceStep captureRanges at: storageIndex.
		rows add: (PCRE2TraceCaptureRow
				 index: storageIndex - 1
				 range: range
				 text: (self textFrom: subjectString range: range)) ].
	^ rows asArray
]

{ #category : 'display' }
PCRE2TracePresenter >> caretLineFor: characterPosition in: sourceString [

	| caretPosition |
	caretPosition := (characterPosition max: 1) min:
		                 sourceString size + 1.
	^ (String new: caretPosition - 1 withAll: Character space) , '^'
]

{ #category : 'initialization' }
PCRE2TracePresenter >> connectPresenters [

	stepsTable whenSelectedItemChangedDo: [ :step |
		self selectedStep: step ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> defaultLayout [

	| bottomPane detailsPane sourcePane |
	sourcePane := SpPanedLayout newLeftToRight
		              positionOfSlider: 50 percent;
		              add: patternText;
		              add: subjectText;
		              yourself.
	detailsPane := SpBoxLayout newTopToBottom
		               spacing: 4;
		               add: capturesTable;
		               add: detailsText;
		               yourself.
	bottomPane := SpPanedLayout newLeftToRight
		              positionOfSlider: 45 percent;
		              add: stepsTable;
		              add: detailsPane;
		              yourself.
	^ SpBoxLayout newTopToBottom
		  borderWidth: 8;
		  spacing: 6;
		  add: statusLabel height: 24;
		  add: sourcePane height: 180;
		  add: bottomPane;
		  yourself
]

{ #category : 'display' }
PCRE2TracePresenter >> detailsTextForStep: aTraceStep [

	| event site |
	event := aTraceStep event.
	site := aTraceStep site.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Step: ';
			  print: aTraceStep index;
			  cr;
			  nextPutAll: 'Kind: ';
			  nextPutAll: aTraceStep debuggerKindLabel;
			  cr;
			  nextPutAll: 'Pattern range: ';
			  nextPutAll: aTraceStep debuggerPatternRangeLabel;
			  cr;
			  nextPutAll: 'Subject position: ';
			  print: aTraceStep subjectPosition;
			  cr;
			  nextPutAll: 'Subject range: ';
			  nextPutAll: aTraceStep debuggerSubjectRangeLabel;
			  cr;
			  nextPutAll: 'Callout: ';
			  nextPutAll: aTraceStep debuggerCalloutLabel;
			  cr.
		  aTraceStep mark ifNotNil: [ :mark |
			  stream
				  nextPutAll: 'Mark: ';
				  nextPutAll: mark;
				  cr ].
		  stream
			  nextPutAll: 'Native pattern offset: ';
			  print: event patternPosition;
			  cr;
			  nextPutAll: 'Native next item length: ';
			  print: event nextItemLength;
			  cr;
			  nextPutAll: 'Native subject offset: ';
			  print: event currentPosition;
			  cr;
			  nextPutAll: 'Native start match offset: ';
			  print: event startMatch;
			  cr;
			  nextPutAll: 'Capture top: ';
			  print: event captureTop;
			  cr;
			  nextPutAll: 'Capture last: ';
			  print: event captureLast;
			  cr;
			  nextPutAll: 'Flags: ';
			  print: event flags.
		  site ifNotNil: [
			  stream
				  cr;
				  cr;
				  nextPutAll: 'Static site pattern offset: ';
				  print: site patternPosition;
				  cr;
				  nextPutAll: 'Static site item length: ';
				  print: site nextItemLength ] ]
]

{ #category : 'display' }
PCRE2TracePresenter >> highlightedTextFor: aString range: anIntervalOrNil [

	| source stop text |
	source := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	anIntervalOrNil ifNil: [ ^ source asText ].
	anIntervalOrNil isEmpty ifTrue: [
		^ (source , String cr
		   , (self caretLineFor: anIntervalOrNil first in: source)) asText ].
	text := source asText.
	stop := anIntervalOrNil last min: source size.
	anIntervalOrNil first <= stop ifTrue: [
		text
			addAttribute: TextEmphasis bold
			from: anIntervalOrNil first
			to: stop.
		text
			addAttribute: (TextColor color: Color red)
			from: anIntervalOrNil first
			to: stop ].
	^ text
]

{ #category : 'initialization' }
PCRE2TracePresenter >> initializeCapturesTable [

	capturesTable := self newTable beResizable.
	capturesTable
		addColumn: (SpStringTableColumn
				 title: 'Capture'
				 evaluated: [ :row | row displayIndex ]);
		addColumn: (SpStringTableColumn
				 title: 'Range'
				 evaluated: [ :row | row displayRange ]);
		addColumn:
			(SpStringTableColumn title: 'Text' evaluated: [ :row | row text ])
]

{ #category : 'initialization' }
PCRE2TracePresenter >> initializePresenters [

	statusLabel := self newLabel.
	patternText := self newText
		               beNotEditable;
		               yourself.
	subjectText := self newText
		               beNotEditable;
		               yourself.
	detailsText := self newText
		               beNotEditable;
		               yourself.
	self initializeStepsTable.
	self initializeCapturesTable.
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PCRE2TracePresenter >> initializeStepsTable [

	stepsTable := self newTable beResizable.
	stepsTable
		addColumn: (SpStringTableColumn
				 title: '#'
				 evaluated: [ :step | step index asString ]);
		addColumn: (SpStringTableColumn
				 title: 'Kind'
				 evaluated: [ :step | step debuggerKindLabel ]);
		addColumn: (SpStringTableColumn
				 title: 'Pattern'
				 evaluated: [ :step | step debuggerPatternRangeLabel ]);
		addColumn: (SpStringTableColumn
				 title: 'Subject'
				 evaluated: [ :step | step debuggerSubjectRangeLabel ]);
		addColumn: (SpStringTableColumn
				 title: 'Callout'
				 evaluated: [ :step | step debuggerCalloutLabel ])
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedStep [

	^ selectedStep
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedStep: aTraceStepOrNil [

	selectedStep := aTraceStepOrNil.
	self updateSelectedStep
]

{ #category : 'initialization' }
PCRE2TracePresenter >> setModelBeforeInitialization: aPCRE2MatchTrace [

	trace := aPCRE2MatchTrace
]

{ #category : 'accessing' }
PCRE2TracePresenter >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
PCRE2TracePresenter >> stepsTable [

	^ stepsTable
]

{ #category : 'display' }
PCRE2TracePresenter >> textFrom: sourceString range: anIntervalOrNil [

	anIntervalOrNil ifNil: [ ^ '' ].
	anIntervalOrNil isEmpty ifTrue: [ ^ '' ].
	^ sourceString
		  copyFrom: (anIntervalOrNil first max: 1)
		  to: (anIntervalOrNil last min: sourceString size)
]

{ #category : 'accessing' }
PCRE2TracePresenter >> trace [

	^ trace
]

{ #category : 'accessing' }
PCRE2TracePresenter >> trace: aPCRE2MatchTraceOrNil [

	trace := aPCRE2MatchTraceOrNil.
	stepsTable ifNotNil: [ self updatePresenter ]
]

{ #category : 'display' }
PCRE2TracePresenter >> traceStatusString [

	trace ifNil: [ ^ 'No trace.' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (trace isMatch
					   ifTrue: [ 'Match' ]
					   ifFalse: [ 'No match' ]);
			  nextPutAll: ' | result code ';
			  print: trace resultCode;
			  nextPutAll: ' | events ';
			  print: trace events size;
			  nextPutAll: ' | callout sites ';
			  print: trace calloutSites size.
		  trace matchedString ifNotNil: [ :matched |
			  stream
				  nextPutAll: ' | matched ';
				  print: matched ] ]
]

{ #category : 'updating' }
PCRE2TracePresenter >> updatePresenter [

	| steps |
	trace ifNil: [
		statusLabel label: 'No trace.'.
		stepsTable items: #(  ).
		selectedStep := nil.
		self updateSelectedStep.
		^ self ].
	steps := trace steps.
	statusLabel label: self traceStatusString.
	stepsTable items: steps.
	selectedStep := steps isEmpty
		                ifTrue: [ nil ]
		                ifFalse: [ steps first ].
	selectedStep ifNotNil: [ stepsTable selectItem: selectedStep ].
	self updateSelectedStep
]

{ #category : 'updating' }
PCRE2TracePresenter >> updateSelectedStep [

	selectedStep ifNil: [
		patternText text: (trace ifNil: [ '' ] ifNotNil: [ trace pattern ]).
		subjectText text:
			(trace ifNil: [ '' ] ifNotNil: [ trace subject asString ]).
		capturesTable items: #(  ).
		detailsText text: ''.
		^ self ].
	patternText text: (self
			 highlightedTextFor: trace pattern
			 range: selectedStep patternRange).
	subjectText text: (self
			 highlightedTextFor: trace subject asString
			 range: selectedStep subjectRange).
	capturesTable items: (self captureRowsForStep: selectedStep).
	detailsText text: (self detailsTextForStep: selectedStep)
]
