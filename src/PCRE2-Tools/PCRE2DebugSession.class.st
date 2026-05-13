"
I am the UI-facing model for a PCRE2 debugging session.

I keep editable pattern and subject strings, compile and run an explicit trace on demand, remember the latest PCRE2MatchTrace, and track the currently selected trace step. Presenters use me as the single session state object so inspector tabs and standalone debugger windows can share the same behavior without owning trace data themselves.
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
		'lastError'
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
	selectedStepIndex := 0
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

{ #category : 'private' }
PCRE2DebugSession >> persistTraceMatch [
	"Keep the final match queryable after native match-data lifetime changes."

	trace ifNil: [ ^ self ].
	trace match ifNotNil: [ :match | match bePersistent ]
]

{ #category : 'stepping' }
PCRE2DebugSession >> previousStep [

	^ self selectStepIndex: selectedStepIndex - 1
]

{ #category : 'tracing' }
PCRE2DebugSession >> runTrace [
	"Compile the current pattern and run an explicit instrumented trace. Normal matcher usage is not affected."

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

{ #category : 'stepping' }
PCRE2DebugSession >> selectStep: aTraceStep [

	aTraceStep ifNil: [
		selectedStepIndex := 0.
		^ self ].
	selectedStepIndex := self steps indexOf: aTraceStep ifAbsent: [ 0 ].
	^ self
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
