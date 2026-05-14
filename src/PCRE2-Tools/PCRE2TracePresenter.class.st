"
I present a PCRE2MatchTrace.

I am designed as a reusable subpresenter: inspector extensions can embed me for an existing trace, and the standalone debugger can reuse me as its trace pane. I show a readable timeline of trace rows, highlighted pattern and subject text for the selected step, focused source-context excerpts, capture ranges, and raw event details.

The trace model remains unchanged. I may group long automatic progress runs into PCRE2TraceStepRow objects so the table is easier to scan while still keeping every original PCRE2TraceStep available for navigation and details.
"
Class {
	#name : 'PCRE2TracePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'trace',
		'stepsTable',
		'patternText',
		'patternContextText',
		'subjectText',
		'subjectContextText',
		'capturesTable',
		'detailsText',
		'statusLabel',
		'selectedStep',
		'selectedRow'
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
PCRE2TracePresenter >> applySourceHighlightTo: aText range: anInterval [

	aText
		addAttribute: (TextBackgroundColor color: (Color red alpha: 0.12))
		from: anInterval first
		to: anInterval last.
	aText
		addAttribute: (TextColor color: Color red)
		from: anInterval first
		to: anInterval last.
	aText
		addAttribute: TextEmphasis bold
		from: anInterval first
		to: anInterval last
]

{ #category : 'display' }
PCRE2TracePresenter >> calloutLabelForRow: aTraceStepRow [

	aTraceStepRow isGroup ifFalse: [
		^ aTraceStepRow firstStep debuggerCalloutLabel ].
	^ aTraceStepRow firstStep debuggerCalloutLabel , ' x'
	  , aTraceStepRow size asString
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

{ #category : 'layout' }
PCRE2TracePresenter >> capturesHelpString [

	^ 'Capture groups produced at the selected trace row.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> capturesTable [

	^ capturesTable
]

{ #category : 'display' }
PCRE2TracePresenter >> combinedRangeForRow: aTraceStepRow using: rangeBlock [

	| first firstRange last ranges |
	ranges := OrderedCollection new.
	aTraceStepRow steps do: [ :step |
		(rangeBlock value: step) ifNotNil: [ :range |
			range isEmpty ifFalse: [ ranges add: range ] ] ].
	firstRange := rangeBlock value: aTraceStepRow firstStep.
	ranges ifEmpty: [ ^ firstRange ].
	first := ranges first first.
	last := ranges first last.
	ranges do: [ :range |
		first := first min: range first.
		last := last max: range last ].
	^ first to: last
]

{ #category : 'initialization' }
PCRE2TracePresenter >> connectPresenters [

	stepsTable whenSelectedItemChangedDo: [ :row | self selectedRow: row ]
]

{ #category : 'display' }
PCRE2TracePresenter >> contextExcerptFor: sourceString from: startIndex to: stopIndex [

	| excerpt |
	(sourceString isEmpty or: [ stopIndex < startIndex ]) ifTrue: [ ^ '' ].
	excerpt := sourceString copyFrom: startIndex to: stopIndex.
	startIndex > 1 ifTrue: [ excerpt := '...' , excerpt ].
	stopIndex < sourceString size ifTrue: [ excerpt := excerpt , '...' ].
	^ excerpt
]

{ #category : 'layout' }
PCRE2TracePresenter >> defaultLayout [

	| bottomPane detailsPane patternPane sourcePane subjectPane |
	patternPane := SpBoxLayout newTopToBottom
		               spacing: 4;
		               add: (self
				                labelledPresenter: patternText
				                label: 'Traced pattern'
				                help: self patternSourceHelpString);
		               add: (self
				                labelledPresenter: patternContextText
				                label: 'Pattern context'
				                help: self patternContextHelpString)
		               height: 88;
		               yourself.
	subjectPane := SpBoxLayout newTopToBottom
		               spacing: 4;
		               add: (self
				                labelledPresenter: subjectText
				                label: 'Traced subject'
				                help: self subjectSourceHelpString);
		               add: (self
				                labelledPresenter: subjectContextText
				                label: 'Subject context'
				                help: self subjectContextHelpString)
		               height: 88;
		               yourself.
	sourcePane := SpPanedLayout newLeftToRight
		              positionOfSlider: 50 percent;
		              add: patternPane;
		              add: subjectPane;
		              yourself.
	detailsPane := SpBoxLayout newTopToBottom
		               spacing: 4;
		               add: (self
				                labelledPresenter: capturesTable
				                label: 'Captures'
				                help: self capturesHelpString);
		               add: (self
				                labelledPresenter: detailsText
				                label: 'Event details'
				                help: self eventDetailsHelpString)
		               height: 130;
		               yourself.
	bottomPane := SpPanedLayout newLeftToRight
		              positionOfSlider: 70 percent;
		              add: (self
				               labelledPresenter: stepsTable
				               label: 'Trace timeline'
				               help: self traceTimelineHelpString);
		              add: detailsPane;
		              yourself.
	^ SpBoxLayout newTopToBottom
		  borderWidth: 8;
		  spacing: 6;
		  add: statusLabel height: 24;
		  add: sourcePane height: 270;
		  add: bottomPane;
		  yourself
]

{ #category : 'accessing' }
PCRE2TracePresenter >> detailsText [

	^ detailsText
]

{ #category : 'display' }
PCRE2TracePresenter >> detailsTextForRow: aTraceStepRow [

	aTraceStepRow isGroup ifFalse: [
		^ self detailsTextForStep: aTraceStepRow representativeStep ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Steps: ';
			  nextPutAll: aTraceStepRow indexLabel;
			  nextPutAll: ' (';
			  nextPutAll: aTraceStepRow kindLabel;
			  nextPut: $);
			  cr;
			  nextPutAll: 'Pattern: ';
			  nextPutAll: (self patternLabelForRow: aTraceStepRow);
			  cr;
			  nextPutAll: 'Subject: ';
			  nextPutAll: (self subjectLabelForRow: aTraceStepRow);
			  cr;
			  nextPutAll: 'Callout: ';
			  nextPutAll: (self calloutLabelForRow: aTraceStepRow);
			  cr;
			  cr;
			  nextPutAll: 'First event';
			  cr;
			  nextPutAll: (self detailsTextForStep: aTraceStepRow firstStep);
			  cr;
			  cr;
			  nextPutAll: 'Last event';
			  cr;
			  nextPutAll: (self detailsTextForStep: aTraceStepRow lastStep) ]
]

{ #category : 'display' }
PCRE2TracePresenter >> detailsTextForStep: aTraceStep [

	| event row site |
	event := aTraceStep event.
	site := aTraceStep site.
	row := PCRE2TraceStepRow steps: { aTraceStep }.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Step: ';
			  print: aTraceStep index;
			  cr;
			  nextPutAll: 'Kind: ';
			  nextPutAll: aTraceStep debuggerKindLabel;
			  cr;
			  nextPutAll: 'Pattern: ';
			  nextPutAll: (self patternLabelForRow: row);
			  cr;
			  nextPutAll: 'Subject: ';
			  nextPutAll: (self subjectLabelForRow: row);
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

{ #category : 'layout' }
PCRE2TracePresenter >> eventDetailsHelpString [

	^ 'Raw PCRE2 callout fields for the selected event or grouped row.'
]

{ #category : 'display' }
PCRE2TracePresenter >> flushProgressRun: pendingSteps into: rows [

	pendingSteps ifEmpty: [ ^ self ].
	pendingSteps size >= self minimumProgressRunSizeForGrouping
		ifTrue: [ rows add: (PCRE2TraceStepRow steps: pendingSteps) ]
		ifFalse: [
			pendingSteps do: [ :step |
				rows add: (PCRE2TraceStepRow steps: { step }) ] ].
	pendingSteps removeAll
]

{ #category : 'display' }
PCRE2TracePresenter >> highlightedTextFor: aString range: anIntervalOrNil [

	| highlightPosition source start stop text |
	source := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	text := source asText.
	(anIntervalOrNil isNil or: [ source isEmpty ]) ifTrue: [ ^ text ].
	anIntervalOrNil isEmpty ifTrue: [
		highlightPosition := (anIntervalOrNil first max: 1) min: source size.
		self
			applySourceHighlightTo: text
			range: (highlightPosition to: highlightPosition).
		^ text ].
	start := anIntervalOrNil first max: 1.
	stop := anIntervalOrNil last min: source size.
	start <= stop ifTrue: [
		self applySourceHighlightTo: text range: (start to: stop) ].
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

	statusLabel := self newLabel
		               help: self statusHelpString;
		               yourself.
	patternText := self newText
		               beNotEditable;
		               yourself.
	patternContextText := self newText
		                      withoutScrollBars;
		                      beNotEditable;
		                      yourself.
	subjectText := self newText
		               beNotEditable;
		               yourself.
	subjectContextText := self newText
		                      withoutScrollBars;
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
		addColumn:
			((SpStringTableColumn
				  title: '#'
				  evaluated: [ :row | row indexLabel ])
				 width: 35;
				 beNotExpandable;
				 yourself);
		addColumn: ((SpStringTableColumn
				  title: 'Kind'
				  evaluated: [ :row | row kindLabel ])
				 width: 75;
				 beNotExpandable;
				 yourself);
		addColumn: ((SpStringTableColumn
				  title: 'Pattern'
				  evaluated: [ :row | self patternLabelForRow: row ])
				 width: 120;
				 beNotExpandable;
				 yourself);
		addColumn: ((SpStringTableColumn
				  title: 'Subject range'
				  evaluated: [ :row | self subjectLabelForRow: row ])
				 width: 90;
				 beNotExpandable;
				 yourself);
		addColumn: ((SpStringTableColumn
				  title: 'Callout'
				  evaluated: [ :row | self calloutLabelForRow: row ])
				 width: 70;
				 beNotExpandable;
				 yourself)
]

{ #category : 'display' }
PCRE2TracePresenter >> isGroupableProgressStep: aTraceStep [

	^ aTraceStep isProgress and: [ aTraceStep event isAutomatic ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> labelledPresenter: aPresenter label: labelString help: helpString [

	| label |
	aPresenter help: helpString.
	label := self newLabel
		         label: labelString;
		         help: helpString;
		         yourself.
	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: label height: 20;
		  add: aPresenter;
		  yourself
]

{ #category : 'display' }
PCRE2TracePresenter >> minimumProgressRunSizeForGrouping [

	^ 4
]

{ #category : 'display' }
PCRE2TracePresenter >> oneLineSourceFor: sourceObject [

	| source |
	source := sourceObject
		          ifNil: [ '' ]
		          ifNotNil: [ sourceObject asString ].
	^ String streamContents: [ :stream |
		  source do: [ :character |
			  (character = Character cr or: [ character = Character lf ])
				  ifTrue: [ stream nextPut: Character space ]
				  ifFalse: [ stream nextPut: character ] ] ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> patternContextHelpString [

	^ 'Focused pattern excerpt around the selected trace row, with the relevant token highlighted.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> patternContextText [

	^ patternContextText
]

{ #category : 'display' }
PCRE2TracePresenter >> patternContextTextForRow: aTraceStepRow range: anIntervalOrNil [

	^ self
		  sourceContextTextFor: trace pattern
		  range: anIntervalOrNil
		  title: 'Pattern ' , (self patternLabelForRow: aTraceStepRow)
		  callout: (self calloutLabelForRow: aTraceStepRow)
]

{ #category : 'display' }
PCRE2TracePresenter >> patternLabelForRow: aTraceStepRow [

	^ self
		  sourceLabelFor: trace pattern
		  range: (self patternRangeForRow: aTraceStepRow)
]

{ #category : 'display' }
PCRE2TracePresenter >> patternRangeForRow: aTraceStepRow [

	^ self
		  combinedRangeForRow: aTraceStepRow
		  using: [ :step | step patternRange ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> patternSourceHelpString [

	^ 'Pattern used by the current trace. Highlight shows the pattern range reached by the selected trace row.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> patternText [

	^ patternText
]

{ #category : 'display' }
PCRE2TracePresenter >> quotedSnippet: aString [

	| clean limit |
	clean := String streamContents: [ :stream |
		         aString do: [ :character |
			         character = Character cr
				         ifTrue: [ stream nextPutAll: '\n' ]
				         ifFalse: [ stream nextPut: character ] ] ].
	limit := 18.
	clean size > limit ifTrue: [
		clean := (clean copyFrom: 1 to: limit - 3) , '...' ].
	^ '"' , clean , '"'
]

{ #category : 'display' }
PCRE2TracePresenter >> rangeLabelFor: anIntervalOrNil in: sourceString [

	anIntervalOrNil ifNil: [ ^ '' ].
	anIntervalOrNil isEmpty ifTrue: [
		anIntervalOrNil first > sourceString size ifTrue: [ ^ 'end' ].
		^ 'at ' , anIntervalOrNil first asString ].
	anIntervalOrNil first = anIntervalOrNil last ifTrue: [
		^ anIntervalOrNil first asString ].
	^ anIntervalOrNil first asString , '-'
	  , anIntervalOrNil last asString
]

{ #category : 'accessing' }
PCRE2TracePresenter >> rowForStep: aTraceStep ifAbsent: absentBlock [

	stepsTable ifNil: [ ^ absentBlock value ].
	^ stepsTable items
		  detect: [ :row | row includesStep: aTraceStep ]
		  ifNone: absentBlock
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedRow [

	^ selectedRow
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedRow: aTraceStepRowOrNil [

	selectedRow := aTraceStepRowOrNil.
	selectedStep := selectedRow
		                ifNil: [ nil ]
		                ifNotNil: [ selectedRow representativeStep ].
	(stepsTable notNil and: [
		 selectedRow notNil and: [ stepsTable selectedItem ~~ selectedRow ] ])
		ifTrue: [ stepsTable selectItem: selectedRow ].
	self updateSelectedStep
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedStep [

	^ selectedStep
]

{ #category : 'accessing' }
PCRE2TracePresenter >> selectedStep: aTraceStepOrNil [

	selectedStep := aTraceStepOrNil.
	selectedRow := nil.
	(stepsTable notNil and: [ selectedStep notNil ]) ifTrue: [
		selectedRow := self rowForStep: selectedStep ifAbsent: [ nil ].
		selectedRow ifNotNil: [
			stepsTable selectItem: selectedRow.
			selectedStep := aTraceStepOrNil ] ].
	self updateSelectedStep
]

{ #category : 'initialization' }
PCRE2TracePresenter >> setModelBeforeInitialization: aPCRE2MatchTrace [

	trace := aPCRE2MatchTrace
]

{ #category : 'display' }
PCRE2TracePresenter >> sourceContextHighlightIntervalFor: anIntervalOrNil contextStart: contextStart titleLineSize: titleLineSize excerpt: excerptString hasLeadingEllipsis: hasLeadingEllipsis [

	| excerptEnd excerptStart highlightStart highlightStop leadingOffset size |
	(anIntervalOrNil isNil or: [ excerptString isEmpty ]) ifTrue: [
		^ nil ].
	excerptStart := titleLineSize + 2.
	excerptEnd := excerptStart + excerptString size - 1.
	leadingOffset := hasLeadingEllipsis
		                 ifTrue: [ 3 ]
		                 ifFalse: [ 0 ].
	highlightStart := excerptStart + leadingOffset
	                  + (anIntervalOrNil first - contextStart).
	highlightStart := (highlightStart max: excerptStart) min: excerptEnd.
	size := anIntervalOrNil isEmpty
		        ifTrue: [ 1 ]
		        ifFalse: [ anIntervalOrNil size ].
	highlightStop := highlightStart + size - 1 min: excerptEnd.
	highlightStop < highlightStart ifTrue: [ ^ nil ].
	^ highlightStart to: highlightStop
]

{ #category : 'display' }
PCRE2TracePresenter >> sourceContextRadius [

	^ 24
]

{ #category : 'display' }
PCRE2TracePresenter >> sourceContextRangeFor: sourceString range: anIntervalOrNil [

	| focusEnd focusStart start stop |
	focusStart := anIntervalOrNil first max: 1.
	focusEnd := anIntervalOrNil isEmpty
		            ifTrue: [ focusStart ]
		            ifFalse: [ anIntervalOrNil last ].
	start := focusStart - self sourceContextRadius max: 1.
	stop := focusEnd + self sourceContextRadius min: sourceString size.
	stop < start ifTrue: [ stop := start min: sourceString size ].
	^ start to: stop
]

{ #category : 'display' }
PCRE2TracePresenter >> sourceContextTextFor: sourceObject range: anIntervalOrNil title: titleString callout: calloutString [

	| excerpt highlightInterval range source start stop text titleLine |
	titleLine := titleString , ' | ' , calloutString.
	source := self oneLineSourceFor: sourceObject.
	anIntervalOrNil ifNil: [ ^ titleLine asText ].
	range := self sourceContextRangeFor: source range: anIntervalOrNil.
	start := range first.
	stop := range last.
	excerpt := self contextExcerptFor: source from: start to: stop.
	text := (titleLine , String cr , excerpt) asText.
	highlightInterval := self
		                     sourceContextHighlightIntervalFor:
		                     anIntervalOrNil
		                     contextStart: start
		                     titleLineSize: titleLine size
		                     excerpt: excerpt
		                     hasLeadingEllipsis: start > 1.
	highlightInterval ifNotNil: [
		self applySourceHighlightTo: text range: highlightInterval ].
	^ text
]

{ #category : 'display' }
PCRE2TracePresenter >> sourceLabelFor: sourceObject range: anIntervalOrNil [

	| label snippet source |
	source := sourceObject
		          ifNil: [ '' ]
		          ifNotNil: [ sourceObject asString ].
	label := self rangeLabelFor: anIntervalOrNil in: source.
	snippet := self textFrom: source range: anIntervalOrNil.
	snippet ifEmpty: [ ^ label ].
	^ label , ' ' , (self quotedSnippet: snippet)
]

{ #category : 'layout' }
PCRE2TracePresenter >> statusHelpString [

	^ 'Summary of the trace result, return code, event count, grouped row count, callout sites, and matched text.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> statusLabel [

	^ statusLabel
]

{ #category : 'display' }
PCRE2TracePresenter >> stepRowsForSteps: traceSteps [

	| pending rows |
	rows := OrderedCollection new.
	pending := OrderedCollection new.
	traceSteps do: [ :step |
		(self isGroupableProgressStep: step)
			ifTrue: [ pending add: step ]
			ifFalse: [
				self flushProgressRun: pending into: rows.
				rows add: (PCRE2TraceStepRow steps: { step }) ] ].
	self flushProgressRun: pending into: rows.
	^ rows asArray
]

{ #category : 'accessing' }
PCRE2TracePresenter >> stepsTable [

	^ stepsTable
]

{ #category : 'layout' }
PCRE2TracePresenter >> subjectContextHelpString [

	^ 'Focused subject excerpt around the selected trace row, with the consumed subject span highlighted.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> subjectContextText [

	^ subjectContextText
]

{ #category : 'display' }
PCRE2TracePresenter >> subjectContextTextForRow: aTraceStepRow range: anIntervalOrNil [

	^ self
		  sourceContextTextFor: trace subject asString
		  range: anIntervalOrNil
		  title: 'Subject ' , (self subjectLabelForRow: aTraceStepRow)
		  callout: (self calloutLabelForRow: aTraceStepRow)
]

{ #category : 'display' }
PCRE2TracePresenter >> subjectLabelForRow: aTraceStepRow [

	^ self
		  rangeLabelFor: (self subjectRangeForRow: aTraceStepRow)
		  in: trace subject asString
]

{ #category : 'display' }
PCRE2TracePresenter >> subjectRangeForRow: aTraceStepRow [

	^ self
		  combinedRangeForRow: aTraceStepRow
		  using: [ :step | step subjectRange ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> subjectSourceHelpString [

	^ 'Subject used by the current trace. Highlight shows the subject range reached by the selected trace row.'
]

{ #category : 'accessing' }
PCRE2TracePresenter >> subjectText [

	^ subjectText
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

	| rowCount |
	trace ifNil: [ ^ 'No trace.' ].
	rowCount := (self stepRowsForSteps: trace steps) size.
	((trace respondsTo: #isFinished) and: [ trace isFinished not ])
		ifTrue: [
			^ String streamContents: [ :stream |
				  stream
					  nextPutAll: 'Live trace';
					  nextPutAll: ' | events ';
					  print: trace events size.
				  rowCount < trace events size ifTrue: [
					  stream
						  nextPutAll: ' | rows ';
						  print: rowCount ].
				  stream
					  nextPutAll: ' | callout sites ';
					  print: trace calloutSites size ] ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (trace isMatch
					   ifTrue: [ 'Match' ]
					   ifFalse: [ 'No match' ]);
			  nextPutAll: ' | result code ';
			  print: trace resultCode;
			  nextPutAll: ' | events ';
			  print: trace events size.
		  rowCount < trace events size ifTrue: [
			  stream
				  nextPutAll: ' | rows ';
				  print: rowCount ].
		  stream
			  nextPutAll: ' | callout sites ';
			  print: trace calloutSites size.
		  trace matchedString ifNotNil: [ :matched |
			  stream
				  nextPutAll: ' | matched ';
				  print: matched ] ]
]

{ #category : 'layout' }
PCRE2TracePresenter >> traceTimelineHelpString [

	^ 'Callout events in execution order. Automatic rows may group repeated progress events.'
]

{ #category : 'updating' }
PCRE2TracePresenter >> updatePresenter [

	| matchingStep previousStep rows |
	previousStep := selectedStep.
	trace ifNil: [
		statusLabel label: 'No trace.'.
		stepsTable items: #(  ).
		selectedRow := nil.
		selectedStep := nil.
		self updateSelectedStep.
		^ self ].
	rows := self stepRowsForSteps: trace steps.
	statusLabel label: self traceStatusString.
	stepsTable items: rows.
	previousStep ifNotNil: [
		selectedRow := rows
			               detect: [ :row | row includesStep: previousStep ]
			               ifNone: [ nil ].
		selectedRow ifNotNil: [
			matchingStep := selectedRow
				                stepMatching: previousStep
				                ifAbsent: [ selectedRow representativeStep ].
			stepsTable selectItem: selectedRow.
			selectedStep := matchingStep.
			self updateSelectedStep.
			^ self ] ].
	selectedRow := rows isEmpty
		               ifTrue: [ nil ]
		               ifFalse: [ rows first ].
	selectedStep := selectedRow
		                ifNil: [ nil ]
		                ifNotNil: [ selectedRow representativeStep ].
	selectedRow ifNotNil: [ stepsTable selectItem: selectedRow ].
	self updateSelectedStep
]

{ #category : 'updating' }
PCRE2TracePresenter >> updateSelectedStep [

	| contextRow patternRange row showsGroup subjectRange |
	selectedStep ifNil: [
		patternText text: (trace ifNil: [ '' ] ifNotNil: [ trace pattern ]).
		patternContextText text: ''.
		subjectText text:
			(trace ifNil: [ '' ] ifNotNil: [ trace subject asString ]).
		subjectContextText text: ''.
		capturesTable items: #(  ).
		detailsText text: ''.
		^ self ].
	row := selectedRow ifNil: [
		       PCRE2TraceStepRow steps: { selectedStep } ].
	showsGroup := row isGroup and: [
		              selectedStep == row representativeStep ].
	contextRow := showsGroup
		              ifTrue: [ row ]
		              ifFalse: [ PCRE2TraceStepRow steps: { selectedStep } ].
	patternRange := showsGroup
		                ifTrue: [ self patternRangeForRow: row ]
		                ifFalse: [ selectedStep patternRange ].
	subjectRange := showsGroup
		                ifTrue: [ self subjectRangeForRow: row ]
		                ifFalse: [ selectedStep subjectRange ].
	patternText text:
		(self highlightedTextFor: trace pattern range: patternRange).
	patternContextText text:
		(self patternContextTextForRow: contextRow range: patternRange).
	subjectText text:
		(self highlightedTextFor: trace subject asString range: subjectRange).
	subjectContextText text:
		(self subjectContextTextForRow: contextRow range: subjectRange).
	capturesTable items: (self captureRowsForStep: selectedStep).
	detailsText text: (showsGroup
			 ifTrue: [ self detailsTextForRow: row ]
			 ifFalse: [ self detailsTextForStep: selectedStep ])
]
