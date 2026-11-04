"
Runs a match under debugger control: a temporary automatic-callout matcher from the configured compiler records its callout events into a `PCRE2TraceRecorder`. Only the public matcher, context and match protocol is used, so either backend can drive it.

The callout block never suspends; it records the event and answers at once, because on the FFI backend suspending would leave the C library parked inside a ThreadedFFI callback. Step mode reruns the match and stops after the requested number of callouts; continue mode runs it to the end, and whenCompletedDo: registers what to do then.
"
Class {
	#name : 'PCRE2LiveDebugRun',
	#superclass : 'Object',
	#instVars : [
		'pattern',
		'subject',
		'compiler',
		'matcher',
		'input',
		'recorder',
		'process',
		'stateSemaphore',
		'controlMode',
		'runState',
		'abortRequested',
		'targetEventCount',
		'lastError',
		'completionCallbacks',
		'callbackMutex'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2LiveDebugRun class >> pattern: patternString subject: subjectString [

	^ self new
		  pattern: patternString;
		  subject: subjectString;
		  yourself
]

{ #category : 'instance creation' }
PCRE2LiveDebugRun class >> pattern: patternString subject: subjectString compiler: aPCRE2Compiler [

	^ self new
		  pattern: patternString;
		  subject: subjectString;
		  compiler: aPCRE2Compiler;
		  yourself
]

{ #category : 'actions' }
PCRE2LiveDebugRun >> abort [

	abortRequested := true.
	self hasActiveProcess ifTrue: [ ^ self ].
	(#( paused idle ) includes: runState) ifFalse: [ ^ self ].
	recorder ifNotNil: [ recorder abortWithResultCode: PCRE2 errorCallout ].
	self runState: #aborted
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> compiler [

	^ compiler ifNil: [ PCRE2Compiler default ]
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> compiler: aPCRE2CompilerOrClass [

	compiler := aPCRE2CompilerOrClass isBehavior
		            ifTrue: [ aPCRE2CompilerOrClass new ]
		            ifFalse: [ aPCRE2CompilerOrClass ]
]

{ #category : 'actions' }
PCRE2LiveDebugRun >> continue [

	self prepare.
	controlMode := #continue.
	self hasActiveProcess ifTrue: [ ^ self ].
	^ self start
]

{ #category : 'running' }
PCRE2LiveDebugRun >> handleCalloutEvent: aPCRE2CalloutEvent [

	abortRequested ifTrue: [ ^ PCRE2 errorCallout ].
	recorder appendEvent: aPCRE2CalloutEvent.
	stateSemaphore signal.
	(controlMode = #step and: [ recorder eventCount >= targetEventCount ]) ifTrue: [ ^ PCRE2 errorCallout ].
	^ 0
]

{ #category : 'running' }
PCRE2LiveDebugRun >> handleMatchResult: resultCode match: matchData [

	(resultCode = PCRE2 errorCallout and: [ abortRequested ]) ifTrue: [
			recorder abortWithResultCode: resultCode.
			self runState: #aborted.
			^ self ].
	(resultCode = PCRE2 errorCallout and: [ controlMode = #step ]) ifTrue: [
			self runState: #paused.
			^ self ].
	resultCode = PCRE2 errorNoMatch ifTrue: [
			recorder finishWithMatch: nil resultCode: resultCode.
			self runState: #completed.
			^ self ].
	matchData input: input.
	matchData prepareForShutdown.
	recorder finishWithMatch: matchData resultCode: resultCode.
	self runState: #completed
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> hasActiveProcess [

	^ process isNotNil and: [ process isTerminated not ]
]

{ #category : 'initialization' }
PCRE2LiveDebugRun >> initialize [

	super initialize.
	pattern := ''.
	subject := ''.
	stateSemaphore := Semaphore new.
	callbackMutex := Mutex new.
	completionCallbacks := OrderedCollection new.
	controlMode := #step.
	runState := #idle.
	abortRequested := false.
	targetEventCount := 1
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> isAborted [

	^ runState = #aborted
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> isFinished [

	^ #( completed aborted failed ) includes: runState
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> isIdle [

	^ runState = #idle
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> isPaused [

	^ runState = #paused
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> isRunning [

	^ runState = #running
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> lastError [

	^ lastError
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> matcher [

	^ matcher
]

{ #category : 'callbacks' }
PCRE2LiveDebugRun >> notifyCompletionCallbacks [

	| callbacks |
	callbackMutex critical: [
			callbacks := completionCallbacks asArray.
			completionCallbacks removeAll ].
	callbacks do: [ :callback |
			[ callback cull: self ]
				on: Error
				do: [ :error | "A failing observer must neither change the run result nor stop the others from being told." error return: nil ] ]
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> pattern [

	^ pattern
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> pattern: aString [

	pattern := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'actions' }
PCRE2LiveDebugRun >> pause [

	self hasActiveProcess ifFalse: [ ^ self ].
	controlMode := #step.
	targetEventCount := recorder eventCount + 1 max: 1
]

{ #category : 'preparing' }
PCRE2LiveDebugRun >> prepare [

	matcher ifNotNil: [ ^ self ].
	matcher := (self compiler compile: pattern) traceMatcher.
	input := matcher preparedInputFor: subject.
	self resetRecorder
]

{ #category : 'running' }
PCRE2LiveDebugRun >> rawMatchInto: matchData [
	"Match through the backend directly, so the stop code of a callout is answered rather than raised as a matcher error."

	| rc |
	matcher validateUsableMatchData: matchData.
	matchData reset.
	matchData namedGroups: matcher namedGroups.
	rc := matcher
		      match: input bytes
		      from: 0
		      to: input size
		      options: matcher options
		      matchData: matchData.
	self recordRawResult: rc in: matchData.
	^ rc
]

{ #category : 'running' }
PCRE2LiveDebugRun >> recordRawResult: resultCode in: matchData [

	matchData resultCode: resultCode.
	matchData count: (resultCode > 0
			 ifTrue: [ resultCode ]
			 ifFalse: [
					 resultCode = PCRE2 errorPartial
						 ifTrue: [ 1 ]
						 ifFalse: [ 0 ] ])
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> recorder [

	^ recorder
]

{ #category : 'private' }
PCRE2LiveDebugRun >> resetRecorder [

	recorder := PCRE2TraceRecorder
		            pattern: pattern
		            patternInput: (matcher compiler preparedPatternFor: pattern)
		            subject: subject
		            input: input
		            calloutSites: matcher calloutSites.
	^ recorder
]

{ #category : 'running' }
PCRE2LiveDebugRun >> runPreparedMatch [

	| match rc |
	[
		[
			matcher context calloutBlock: [ :event | self handleCalloutEvent: event ].
			match := matcher newMatchData.
			rc := self rawMatchInto: match.
			self handleMatchResult: rc match: match ]
			on: Error
			do: [ :error |
					abortRequested
						ifTrue: [
								recorder abortWithResultCode: PCRE2 errorCallout.
								self runState: #aborted ]
						ifFalse: [
								lastError := error messageText ifNil: [ error printString ].
								recorder ifNotNil: [ recorder failWithError: lastError ].
								self runState: #failed ] ] ] ensure: [ matcher ifNotNil: [ matcher context clearCallout ] ]
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> runState [

	^ runState
]

{ #category : 'private' }
PCRE2LiveDebugRun >> runState: aSymbol [

	| becameFinished |
	runState := aSymbol.
	stateSemaphore signal.
	becameFinished := self isFinished.
	becameFinished ifTrue: [ self notifyCompletionCallbacks ].
	^ runState
]

{ #category : 'running' }
PCRE2LiveDebugRun >> start [

	self prepare.
	self hasActiveProcess ifTrue: [ ^ self ].
	abortRequested := false.
	lastError := nil.
	self resetRecorder.
	self runState: #running.
	process := [ self runPreparedMatch ] forkNamed: 'PCRE2 live debug run'
]

{ #category : 'running' }
PCRE2LiveDebugRun >> startContinuing [

	controlMode := #continue.
	^ self start
]

{ #category : 'actions' }
PCRE2LiveDebugRun >> step [

	self prepare.
	self hasActiveProcess ifTrue: [ ^ self ].
	controlMode := #step.
	targetEventCount := recorder eventCount + 1 max: 1.
	^ self start
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> subject [

	^ subject
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> subject: aString [

	subject := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'waiting' }
PCRE2LiveDebugRun >> waitForCompletionMilliseconds: timeoutMilliseconds [

	^ self waitUntil: [ self isFinished ] timeoutMilliseconds: timeoutMilliseconds
]

{ #category : 'waiting' }
PCRE2LiveDebugRun >> waitForPauseOrFinishMilliseconds: timeoutMilliseconds [

	^ self waitUntil: [ self isPaused or: [ self isFinished ] ] timeoutMilliseconds: timeoutMilliseconds
]

{ #category : 'waiting' }
PCRE2LiveDebugRun >> waitUntil: conditionBlock timeoutMilliseconds: timeoutMilliseconds [

	| deadline remaining |
	deadline := Time millisecondClockValue + timeoutMilliseconds.
	[ conditionBlock value ] whileFalse: [
			remaining := deadline - Time millisecondClockValue.
			remaining <= 0 ifTrue: [ ^ false ].
			stateSemaphore waitTimeoutMilliseconds: (remaining min: 20) ].
	^ true
]

{ #category : 'callbacks' }
PCRE2LiveDebugRun >> whenCompletedDo: aBlock [
	"Evaluate aBlock with me when the run ends, or at once if it has."

	| shouldRunNow |
	callbackMutex critical: [
			shouldRunNow := self isFinished.
			shouldRunNow ifFalse: [ completionCallbacks add: aBlock ] ].
	shouldRunNow ifTrue: [ aBlock cull: self ]
]
