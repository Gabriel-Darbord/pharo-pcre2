"
Runs PCRE2 matches under debugger control.

I compile a temporary automatic-callout matcher with the configured compiler and record PCRE2CalloutEvent snapshots into a PCRE2TraceRecorder. I never suspend inside the native callback: callbacks append the event and immediately return either success or PCRE2_ERROR_CALLOUT. This keeps ThreadedFFI callback unwinding simple and avoids leaving PCRE2 parked inside Pharo UI control flow.

Step mode records a deterministic prefix by rerunning the match and stopping after the requested callout count. Continue mode runs the same instrumented matcher to completion. Clients can register completion callbacks with whenCompletedDo: to refresh after a continued run finishes.
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
	self hasActiveProcess ifFalse: [
		(runState = #paused or: [ runState = #idle ]) ifTrue: [
			recorder ifNotNil: [
				recorder abortWithResultCode: PCRE2 errorCallout ].
			self runState: #aborted ] ].
	^ self
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
	(controlMode = #step and: [ recorder events size >= targetEventCount ])
		ifTrue: [ ^ PCRE2 errorCallout ].
	^ 0
]

{ #category : 'running' }
PCRE2LiveDebugRun >> handleMatchResult: resultCode match: matchData [

	(resultCode = PCRE2 errorCallout and: [ abortRequested ]) ifTrue: [
		recorder abortWithResultCode: resultCode.
		self runState: #aborted.
		^ self ].
	(resultCode = PCRE2 errorCallout and: [ controlMode = #step ])
		ifTrue: [
			self runState: #paused.
			^ self ].
	resultCode = PCRE2 errorNoMatch ifTrue: [
		recorder finishWithMatch: nil resultCode: resultCode.
		self runState: #completed.
		^ self ].
	input recordOn: matchData.
	matchData bePersistent.
	recorder finishWithMatch: matchData resultCode: resultCode.
	self runState: #completed
]

{ #category : 'testing' }
PCRE2LiveDebugRun >> hasActiveProcess [

	^ process notNil and: [ process isTerminated not ]
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
			do: [ :error | "Completion callbacks are observers; they must not change the recorded run result."
				 ] ].
	^ self
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

	self hasActiveProcess ifTrue: [
		controlMode := #step.
		targetEventCount := recorder events size + 1 max: 1 ].
	^ self
]

{ #category : 'preparing' }
PCRE2LiveDebugRun >> prepare [

	matcher ifNotNil: [ ^ self ].
	matcher := (self compiler compile: pattern) traceMatcher.
	input := matcher preparedInputFor: subject.
	self resetRecorder.
	^ self
]

{ #category : 'running' }
PCRE2LiveDebugRun >> rawMatchInto: matchData [
	"Run the native match directly so debugger-stop callout return codes remain observable instead of being raised as normal matcher errors."

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
	resultCode > 0 ifTrue: [
		matchData count: resultCode.
		^ self ].
	resultCode = PCRE2 errorPartial
		ifTrue: [ matchData count: 1 ]
		ifFalse: [ matchData count: 0 ]
]

{ #category : 'accessing' }
PCRE2LiveDebugRun >> recorder [

	^ recorder
]

{ #category : 'private' }
PCRE2LiveDebugRun >> resetRecorder [
	"Start a fresh deterministic trace prefix for this run."

	recorder := PCRE2TraceRecorder
		            pattern: pattern
		            patternInput:
		            (matcher compiler preparedPatternFor: pattern)
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
	matcher context calloutBlock: [ :event |
		self handleCalloutEvent: event ].
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
					self runState: #failed ] ] ] ensure: [
		matcher ifNotNil: [ matcher context clearCallout ] ]
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
	process := [ self runPreparedMatch ] forkNamed:
		           'PCRE2 live debug run'.
	^ self
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
	targetEventCount := recorder events size + 1 max: 1.
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

	^ self
		  waitUntil: [ self isFinished ]
		  timeoutMilliseconds: timeoutMilliseconds
]

{ #category : 'waiting' }
PCRE2LiveDebugRun >> waitForPauseOrFinishMilliseconds: timeoutMilliseconds [

	^ self
		  waitUntil: [ self isPaused or: [ self isFinished ] ]
		  timeoutMilliseconds: timeoutMilliseconds
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
	"Evaluate aBlock with me when this run reaches a terminal state. If I am already finished, evaluate it immediately."

	| shouldRunNow |
	callbackMutex critical: [
		shouldRunNow := self isFinished.
		shouldRunNow ifFalse: [ completionCallbacks add: aBlock ] ].
	shouldRunNow ifTrue: [ aBlock cull: self ].
	^ self
]
