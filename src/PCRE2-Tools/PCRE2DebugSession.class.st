"
I am the UI-facing model for a PCRE2 debugging session.

I keep editable pattern and subject strings, run either a complete trace or a controlled stepping run, remember the current trace/recorder, and track the selected recorded step. Presenters use me as the single session state object so inspector tabs and standalone debugger windows can share behavior without owning trace data themselves.

Trace-all mode produces a completed PCRE2MatchTrace in one operation. Step-live mode delegates execution to PCRE2LiveDebugRun, which records callout prefixes without suspending inside the native callback.
"
Class {
	#name : 'PCRE2DebugSession',
	#superclass : 'Object',
	#instVars : [
		'pattern',
		'subject',
		'maximumSteps',
		'matcher',
		'trace',
		'selectedStepIndex',
		'lastError',
		'executionMode',
		'liveRun'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2DebugSession class >> pattern: patternString subject: subjectString [

	^ self new
		  pattern: patternString;
		  subject: subjectString;
		  yourself
]

{ #category : 'live debugging' }
PCRE2DebugSession >> abortLiveRun [

	liveRun ifNil: [ ^ self ].
	liveRun abort.
	liveRun waitForCompletionMilliseconds: 1000.
	self refreshLiveTrace.
	^ self
]

{ #category : 'live debugging' }
PCRE2DebugSession >> continueLiveRun [

	| run |
	executionMode := #stepLive.
	run := self ensureLiveRun.
	run ifNil: [ ^ nil ].
	run continue.
	^ self refreshLiveTrace
]

{ #category : 'private' }
PCRE2DebugSession >> ensureLiveRun [

	(liveRun isNil or: [ liveRun isFinished ]) ifTrue: [
		^ self prepareLiveRun ].
	^ liveRun
]

{ #category : 'accessing' }
PCRE2DebugSession >> executionMode [

	^ executionMode
]

{ #category : 'accessing' }
PCRE2DebugSession >> executionMode: aSymbol [

	executionMode := aSymbol = #stepLive
		                 ifTrue: [ #stepLive ]
		                 ifFalse: [ #traceAll ]
]

{ #category : 'stepping' }
PCRE2DebugSession >> firstStep [

	^ self selectStepIndex: 1
]

{ #category : 'testing' }
PCRE2DebugSession >> hasError [

	^ lastError notNil
]

{ #category : 'testing' }
PCRE2DebugSession >> hasTrace [

	^ trace notNil
]

{ #category : 'initialization' }
PCRE2DebugSession >> initialize [

	super initialize.
	pattern := ''.
	subject := ''.
	maximumSteps := 1000.
	selectedStepIndex := 0.
	executionMode := #traceAll
]

{ #category : 'accessing' }
PCRE2DebugSession >> lastError [

	^ lastError
]

{ #category : 'stepping' }
PCRE2DebugSession >> lastStep [

	^ self selectStepIndex: self stepCount
]

{ #category : 'accessing' }
PCRE2DebugSession >> liveRun [

	^ liveRun
]

{ #category : 'live debugging' }
PCRE2DebugSession >> liveRunState [

	^ liveRun ifNil: [ #idle ] ifNotNil: [ liveRun runState ]
]

{ #category : 'status' }
PCRE2DebugSession >> liveStatusString [

	liveRun ifNil: [ ^ 'Live debugger idle.' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Live ';
			  nextPutAll: liveRun runState asString.
		  trace ifNotNil: [
			  stream
				  nextPutAll: ' | steps ';
				  print: self stepCount;
				  nextPutAll: ' | events ';
				  print: trace events size.
			  trace isFinished ifTrue: [
				  stream
					  nextPutAll: ' | result code ';
					  print: trace resultCode.
				  trace matchedString ifNotNil: [ :matched |
					  stream
						  nextPutAll: ' | matched ';
						  print: matched ] ].
			  trace isAborted ifTrue: [ stream nextPutAll: ' | aborted' ] ].
		  liveRun lastError ifNotNil: [ :errorText |
			  stream
				  nextPutAll: ' | error ';
				  nextPutAll: errorText ] ]
]

{ #category : 'accessing' }
PCRE2DebugSession >> matcher [

	^ matcher
]

{ #category : 'accessing' }
PCRE2DebugSession >> maximumSteps [

	^ maximumSteps
]

{ #category : 'accessing' }
PCRE2DebugSession >> maximumSteps: anInteger [

	maximumSteps := 1 max: anInteger asInteger
]

{ #category : 'stepping' }
PCRE2DebugSession >> nextStep [

	^ self selectStepIndex: selectedStepIndex + 1
]

{ #category : 'accessing' }
PCRE2DebugSession >> pattern [

	^ pattern
]

{ #category : 'accessing' }
PCRE2DebugSession >> pattern: aString [

	pattern := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
PCRE2DebugSession >> pattern: patternString subject: subjectString maximumSteps: stepLimit [
	"Update debugger inputs. A changed pattern or subject invalidates an in-progress live run."

	| newPattern newSubject |
	newPattern := patternString
		              ifNil: [ '' ]
		              ifNotNil: [ patternString asString ].
	newSubject := subjectString
		              ifNil: [ '' ]
		              ifNotNil: [ subjectString asString ].
	(pattern ~= newPattern or: [ subject ~= newSubject ]) ifTrue: [
		self stopLiveRun.
		trace := nil.
		selectedStepIndex := 0.
		lastError := nil ].
	pattern := newPattern.
	subject := newSubject.
	self maximumSteps: stepLimit.
	^ self
]

{ #category : 'live debugging' }
PCRE2DebugSession >> pauseLiveRun [

	liveRun ifNil: [ ^ self ].
	liveRun pause.
	self refreshLiveTrace.
	^ self
]

{ #category : 'private' }
PCRE2DebugSession >> persistTraceMatch [
	"Keep the final match queryable after native match-data lifetime changes."

	trace ifNil: [ ^ self ].
	trace match ifNotNil: [ :match | match bePersistent ]
]

{ #category : 'live debugging' }
PCRE2DebugSession >> prepareLiveRun [
	"Compile a fresh automatic-callout matcher for live stepping."

	lastError := nil.
	matcher := nil.
	trace := nil.
	selectedStepIndex := 0.
	liveRun := PCRE2LiveDebugRun pattern: pattern subject: subject.
	[
	liveRun prepare.
	matcher := liveRun matcher.
	trace := liveRun recorder ]
		on: Error
		do: [ :error |
			lastError := error messageText ifNil: [ error printString ].
			matcher := nil.
			trace := nil.
			liveRun := nil ].
	^ liveRun
]

{ #category : 'stepping' }
PCRE2DebugSession >> previousStep [

	^ self selectStepIndex: selectedStepIndex - 1
]

{ #category : 'live debugging' }
PCRE2DebugSession >> refreshLiveTrace [

	liveRun ifNil: [ ^ trace ].
	trace := liveRun recorder.
	liveRun lastError ifNotNil: [ :errorText | lastError := errorText ].
	trace ifNil: [
		selectedStepIndex := 0.
		^ trace ].
	self stepCount = 0
		ifTrue: [ selectedStepIndex := 0 ]
		ifFalse: [
			selectedStepIndex = 0 ifTrue: [ selectedStepIndex := 1 ].
			selectedStepIndex := selectedStepIndex min: self stepCount ].
	^ trace
]

{ #category : 'tracing' }
PCRE2DebugSession >> runTrace [
	"Compile the current pattern and run an explicit instrumented trace. Normal matcher usage is not affected."

	self stopLiveRun.
	executionMode := #traceAll.
	lastError := nil.
	matcher := nil.
	trace := nil.
	selectedStepIndex := 0.
	[
	matcher := pattern asPerlCompatibleRegex.
	trace := matcher traceMatch: subject.
	self persistTraceMatch.
	selectedStepIndex := self stepCount = 0
		                     ifTrue: [ 0 ]
		                     ifFalse: [ 1 ] ]
		on: Error
		do: [ :error |
			lastError := error messageText ifNil: [ error printString ].
			matcher := nil.
			trace := nil.
			selectedStepIndex := 0 ].
	^ trace
]

{ #category : 'accessing' }
PCRE2DebugSession >> selectStep: aTraceStep [

	aTraceStep ifNil: [
		selectedStepIndex := 0.
		^ self ].
	^ self selectStepIndex: aTraceStep index
]

{ #category : 'stepping' }
PCRE2DebugSession >> selectStepIndex: anInteger [

	self stepCount = 0 ifTrue: [
		selectedStepIndex := 0.
		^ self ].
	selectedStepIndex := (anInteger asInteger max: 1) min: self stepCount.
	^ self
]

{ #category : 'stepping' }
PCRE2DebugSession >> selectedStep [

	(selectedStepIndex between: 1 and: self stepCount) ifFalse: [ ^ nil ].
	^ self steps at: selectedStepIndex
]

{ #category : 'accessing' }
PCRE2DebugSession >> selectedStepIndex [

	^ selectedStepIndex
]

{ #category : 'status' }
PCRE2DebugSession >> statusString [

	lastError ifNotNil: [ ^ 'Error: ' , lastError ].
	executionMode = #stepLive ifTrue: [ ^ self liveStatusString ].
	trace ifNil: [ ^ 'No trace yet.' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (trace isMatch
					   ifTrue: [ 'Match' ]
					   ifFalse: [ 'No match' ]);
			  nextPutAll: ' | result code ';
			  print: trace resultCode;
			  nextPutAll: ' | steps ';
			  print: self stepCount.
		  self traceWasLimited ifTrue: [
			  stream
				  nextPutAll: ' shown of ';
				  print: trace events size ].
		  trace matchedString ifNotNil: [ :matched |
			  stream
				  nextPutAll: ' | matched ';
				  print: matched ] ]
]

{ #category : 'stepping' }
PCRE2DebugSession >> stepCount [

	^ self steps size
]

{ #category : 'live debugging' }
PCRE2DebugSession >> stepLiveRun [

	| run |
	executionMode := #stepLive.
	run := self ensureLiveRun.
	run ifNil: [ ^ nil ].
	run step.
	run waitForPauseOrFinishMilliseconds: 1000.
	self refreshLiveTrace.
	self lastStep.
	^ trace
]

{ #category : 'status' }
PCRE2DebugSession >> stepStatusString [

	self stepCount = 0 ifTrue: [ ^ 'Step 0 / 0' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Step ';
			  print: selectedStepIndex;
			  nextPutAll: ' / ';
			  print: self stepCount ]
]

{ #category : 'accessing' }
PCRE2DebugSession >> steps [

	| allSteps |
	trace ifNil: [ ^ #(  ) ].
	allSteps := trace steps.
	^ allSteps first: (maximumSteps min: allSteps size)
]

{ #category : 'private' }
PCRE2DebugSession >> stopLiveRun [
	"Stop a live run before replacing it. The existing trace recorder is intentionally left alone until the caller installs new state."

	liveRun ifNil: [ ^ self ].
	liveRun isFinished ifFalse: [
		liveRun abort.
		liveRun waitForCompletionMilliseconds: 250 ].
	liveRun := nil.
	^ self
]

{ #category : 'accessing' }
PCRE2DebugSession >> subject [

	^ subject
]

{ #category : 'accessing' }
PCRE2DebugSession >> subject: aString [

	subject := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
PCRE2DebugSession >> trace [

	^ trace
]

{ #category : 'stepping' }
PCRE2DebugSession >> traceWasLimited [

	trace ifNil: [ ^ false ].
	^ trace events size > maximumSteps
]

{ #category : 'live debugging' }
PCRE2DebugSession >> waitForLiveCompletionMilliseconds: timeoutMilliseconds [

	| completed |
	liveRun ifNil: [ ^ false ].
	[
	completed := liveRun waitForCompletionMilliseconds:
		             timeoutMilliseconds ] ensure: [ self refreshLiveTrace ].
	^ completed
]

{ #category : 'live debugging' }
PCRE2DebugSession >> waitForLivePauseOrFinishMilliseconds: timeoutMilliseconds [

	| completed |
	liveRun ifNil: [ ^ false ].
	[
	completed := liveRun waitForPauseOrFinishMilliseconds:
		             timeoutMilliseconds ] ensure: [ self refreshLiveTrace ].
	^ completed
]
