"
I record PCRE2 callout events as they arrive.

A completed PCRE2MatchTrace is a fixed description of one instrumented match. I am the mutable counterpart used by live debugging: callbacks append PCRE2CalloutEvent snapshots to me while PCRE2 is still running, and presenters can ask me the same trace-style questions to display the partial execution.

When matching finishes, I can answer a normal PCRE2MatchTrace snapshot through asTrace. This keeps the live debugger and the existing trace viewer on the same model vocabulary without making PCRE2MatchTrace itself mutable.
"
Class {
	#name : 'PCRE2TraceRecorder',
	#superclass : 'Object',
	#instVars : [
		'pattern',
		'subject',
		'input',
		'calloutSites',
		'events',
		'match',
		'resultCode',
		'finished',
		'aborted',
		'lastError'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2TraceRecorder class >> pattern: patternString subject: subjectObject input: aPCRE2UTF8Input calloutSites: calloutSiteArray [

	^ self new
		  initializePattern: patternString
		  subject: subjectObject
		  input: aPCRE2UTF8Input
		  calloutSites: calloutSiteArray
]

{ #category : 'recording' }
PCRE2TraceRecorder >> abortWithResultCode: anInteger [

	aborted := true.
	^ self finishWithMatch: nil resultCode: anInteger
]

{ #category : 'recording' }
PCRE2TraceRecorder >> appendEvent: aPCRE2CalloutEvent [

	events add: aPCRE2CalloutEvent.
	^ aPCRE2CalloutEvent
]

{ #category : 'converting' }
PCRE2TraceRecorder >> asTrace [

	^ PCRE2MatchTrace
		  pattern: pattern
		  subject: subject
		  input: input
		  calloutSites: calloutSites
		  events: events asArray
		  match: match
		  resultCode: resultCode
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> calloutSiteForEvent: aPCRE2CalloutEvent [

	^ self asTrace calloutSiteForEvent: aPCRE2CalloutEvent
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: absentBlock [

	^ self asTrace
		  calloutSiteForEvent: aPCRE2CalloutEvent
		  ifAbsent: absentBlock
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> calloutSites [

	^ calloutSites
]

{ #category : 'capture access' }
PCRE2TraceRecorder >> captureRangesAtEvent: aPCRE2CalloutEvent [

	^ self asTrace captureRangesAtEvent: aPCRE2CalloutEvent
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> events [

	^ events asArray
]

{ #category : 'enumerating' }
PCRE2TraceRecorder >> eventsDo: aBlock [

	events do: aBlock
]

{ #category : 'enumerating' }
PCRE2TraceRecorder >> eventsWithSitesDo: aBlock [

	^ self asTrace eventsWithSitesDo: aBlock
]

{ #category : 'recording' }
PCRE2TraceRecorder >> failWithError: errorString [

	lastError := errorString.
	finished := true.
	^ self
]

{ #category : 'recording' }
PCRE2TraceRecorder >> finishWithMatch: aPCRE2MatchOrNil resultCode: anInteger [

	match := aPCRE2MatchOrNil.
	resultCode := anInteger.
	finished := true.
	^ self
]

{ #category : 'initialization' }
PCRE2TraceRecorder >> initialize [

	super initialize.
	events := OrderedCollection new.
	finished := false.
	aborted := false
]

{ #category : 'initialization' }
PCRE2TraceRecorder >> initializePattern: patternString subject: subjectObject input: aPCRE2UTF8Input calloutSites: calloutSiteArray [

	pattern := patternString.
	subject := subjectObject.
	input := aPCRE2UTF8Input.
	calloutSites := calloutSiteArray ifNil: [ #(  ) ].
	events := OrderedCollection new.
	finished := false.
	aborted := false.
	^ self
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> input [

	^ input
]

{ #category : 'testing' }
PCRE2TraceRecorder >> isAborted [

	^ aborted
]

{ #category : 'testing' }
PCRE2TraceRecorder >> isFinished [

	^ finished
]

{ #category : 'testing' }
PCRE2TraceRecorder >> isMatch [

	finished ifFalse: [ ^ false ].
	^ self asTrace isMatch
]

{ #category : 'testing' }
PCRE2TraceRecorder >> isPartial [

	finished ifFalse: [ ^ false ].
	^ self asTrace isPartial
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> lastError [

	^ lastError
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> match [

	^ match
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> matchedString [

	finished ifFalse: [ ^ nil ].
	^ self asTrace matchedString
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> pattern [

	^ pattern
]

{ #category : 'decoding' }
PCRE2TraceRecorder >> patternCharacterRangeForEvent: aPCRE2CalloutEvent [

	^ self asTrace patternCharacterRangeForEvent: aPCRE2CalloutEvent
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> resultCode [

	^ resultCode
]

{ #category : 'debugging' }
PCRE2TraceRecorder >> stepForEvent: aPCRE2CalloutEvent index: stepIndex [

	^ self asTrace stepForEvent: aPCRE2CalloutEvent index: stepIndex
]

{ #category : 'debugging' }
PCRE2TraceRecorder >> steps [

	^ self asTrace steps
]

{ #category : 'debugging' }
PCRE2TraceRecorder >> stepsDo: aBlock [

	^ self asTrace stepsDo: aBlock
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> subject [

	^ subject
]

{ #category : 'decoding' }
PCRE2TraceRecorder >> subjectCharacterPositionAtEvent: aPCRE2CalloutEvent [

	^ self asTrace subjectCharacterPositionAtEvent: aPCRE2CalloutEvent
]

{ #category : 'decoding' }
PCRE2TraceRecorder >> subjectCharacterRangeAtEvent: aPCRE2CalloutEvent [

	^ self asTrace subjectCharacterRangeAtEvent: aPCRE2CalloutEvent
]
