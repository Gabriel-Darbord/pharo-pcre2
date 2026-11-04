"
I record callout events as they arrive: the mutable counterpart of `PCRE2MatchTrace` for live debugging, to which a callout block appends while the match runs. I answer trace questions through a `PCRE2MatchTrace` snapshot of what is recorded so far, rebuilt only after a new event; once the match ends, asTrace is that snapshot, final.
"
Class {
	#name : 'PCRE2TraceRecorder',
	#superclass : 'Object',
	#instVars : [
		'pattern',
		'patternInput',
		'subject',
		'input',
		'calloutSites',
		'events',
		'match',
		'resultCode',
		'finished',
		'aborted',
		'lastError',
		'traceSnapshot'
	],
	#category : 'PCRE2-Tools-Debugging',
	#package : 'PCRE2-Tools',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
PCRE2TraceRecorder class >> pattern: patternString patternInput: patternInputObject subject: subjectObject input: aPCRE2Input calloutSites: calloutSiteArray [

	^ self new
		  initializePattern: patternString
		  patternInput: patternInputObject
		  subject: subjectObject
		  input: aPCRE2Input
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
	self invalidateSnapshot.
	^ aPCRE2CalloutEvent
]

{ #category : 'converting' }
PCRE2TraceRecorder >> asTrace [
	"Answer a PCRE2MatchTrace of what is recorded so far, kept until a new event or the result changes it."

	^ traceSnapshot ifNil: [
			  traceSnapshot := PCRE2MatchTrace
				                   pattern: pattern
				                   patternInput: patternInput
				                   subject: subject
				                   input: input
				                   calloutSites: calloutSites
				                   events: events asArray
				                   match: match
				                   resultCode: resultCode ]
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> calloutSiteForEvent: aPCRE2CalloutEvent [

	^ self asTrace calloutSiteForEvent: aPCRE2CalloutEvent
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: absentBlock [

	^ self asTrace calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: absentBlock
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
PCRE2TraceRecorder >> eventCount [
	"Answer how many events have been recorded, without copying them."

	^ events size
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
	self invalidateSnapshot
]

{ #category : 'recording' }
PCRE2TraceRecorder >> finishWithMatch: aPCRE2MatchOrNil resultCode: anInteger [

	match := aPCRE2MatchOrNil.
	resultCode := anInteger.
	finished := true.
	self invalidateSnapshot
]

{ #category : 'initialization' }
PCRE2TraceRecorder >> initialize [

	super initialize.
	events := OrderedCollection new.
	calloutSites := #(  ).
	finished := false.
	aborted := false
]

{ #category : 'initialization' }
PCRE2TraceRecorder >> initializePattern: patternString patternInput: patternInputObject subject: subjectObject input: aPCRE2Input calloutSites: calloutSiteArray [

	pattern := patternString.
	patternInput := patternInputObject.
	subject := subjectObject.
	input := aPCRE2Input.
	calloutSiteArray ifNotNil: [ calloutSites := calloutSiteArray ]
]

{ #category : 'accessing' }
PCRE2TraceRecorder >> input [

	^ input
]

{ #category : 'private' }
PCRE2TraceRecorder >> invalidateSnapshot [

	traceSnapshot := nil
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
PCRE2TraceRecorder >> patternInput [

	^ patternInput
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
