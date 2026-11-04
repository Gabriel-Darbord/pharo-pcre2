"
I describe one instrumented match attempt: the static callout sites, the runtime callout events, the match result, and the translation of code-unit offsets to character positions. The trace comes from a temporary matcher compiled with automatic callouts and run without JIT, so the traced matcher is left unchanged. `steps` turns the events into `PCRE2TraceStep`s for a debugger or trace viewer.
"
Class {
	#name : 'PCRE2MatchTrace',
	#superclass : 'Object',
	#instVars : [
		'pattern',
		'patternInput',
		'subject',
		'input',
		'calloutSites',
		'events',
		'match',
		'resultCode'
	],
	#category : 'PCRE2-Trace',
	#package : 'PCRE2-Trace'
}

{ #category : 'instance creation' }
PCRE2MatchTrace class >> pattern: patternString patternInput: patternInputObject subject: subjectObject input: aPCRE2Input calloutSites: calloutSiteArray events: eventArray match: aMatchOrNil resultCode: anInteger [

	^ self new
		  initializePattern: patternString
		  patternInput: patternInputObject
		  subject: subjectObject
		  input: aPCRE2Input
		  calloutSites: calloutSiteArray
		  events: eventArray
		  match: aMatchOrNil
		  resultCode: anInteger
]

{ #category : 'accessing' }
PCRE2MatchTrace >> calloutSiteForEvent: aPCRE2CalloutEvent [

	^ self calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: [ nil ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: absentBlock [

	^ calloutSites detect: [ :site | site matchesEvent: aPCRE2CalloutEvent ] ifNone: absentBlock
]

{ #category : 'accessing' }
PCRE2MatchTrace >> calloutSites [

	^ calloutSites
]

{ #category : 'capture access' }
PCRE2MatchTrace >> captureRangesAtEvent: aPCRE2CalloutEvent [
	"Answer character ranges for the callout event ovector. Nil entries are unset captures."

	| ranges |
	ranges := Array new: aPCRE2CalloutEvent captureTop.
	1 to: aPCRE2CalloutEvent captureTop do: [ :pairIndex |
			| offsetPair |
			offsetPair := aPCRE2CalloutEvent offsetsAt: pairIndex.
			ranges at: pairIndex put: ((self offsetPairIsUnset: offsetPair) ifFalse: [
					 self subjectCharacterRangeFromStartOffset: offsetPair first endOffset: offsetPair second ]) ].
	^ ranges
]

{ #category : 'accessing' }
PCRE2MatchTrace >> eventCount [

	^ events size
]

{ #category : 'accessing' }
PCRE2MatchTrace >> events [

	^ events
]

{ #category : 'enumerating' }
PCRE2MatchTrace >> eventsDo: aBlock [

	events do: aBlock
]

{ #category : 'enumerating' }
PCRE2MatchTrace >> eventsWithSitesDo: aBlock [
	"Evaluate aBlock with each runtime event and its matching static callout site, if any."

	events do: [ :event | aBlock value: event value: (self calloutSiteForEvent: event) ]
]

{ #category : 'initialization' }
PCRE2MatchTrace >> initializePattern: patternString patternInput: patternInputObject subject: subjectObject input: aPCRE2Input calloutSites: calloutSiteArray events: eventArray match: aMatchOrNil resultCode: anInteger [

	pattern := patternString.
	patternInput := patternInputObject.
	subject := subjectObject.
	input := aPCRE2Input.
	calloutSites := calloutSiteArray.
	events := eventArray.
	match := aMatchOrNil.
	resultCode := anInteger
]

{ #category : 'accessing' }
PCRE2MatchTrace >> input [

	^ input
]

{ #category : 'testing' }
PCRE2MatchTrace >> isFinished [
	"A recorded trace is complete; a live run can answer false."

	^ true
]

{ #category : 'testing' }
PCRE2MatchTrace >> isFullMatch [
	"Answer whether the complete match spans the prepared subject input."

	self isMatch ifFalse: [ ^ false ].
	match offsetsDo: [ :start :end | ^ start = 1 and: [ end = input size ] ].
	^ false
]

{ #category : 'testing' }
PCRE2MatchTrace >> isMatch [

	^ match isNotNil and: [ match isComplete ]
]

{ #category : 'testing' }
PCRE2MatchTrace >> isPartial [

	^ match isNotNil and: [ match isPartial ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> match [

	^ match
]

{ #category : 'accessing' }
PCRE2MatchTrace >> matchedString [

	^ match ifNotNil: [ match readMatch ]
]

{ #category : 'private' }
PCRE2MatchTrace >> offsetPairIsUnset: offsetPair [

	^ offsetPair first = PCRE2 unsetOffset or: [ offsetPair second = PCRE2 unsetOffset ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> pattern [

	^ pattern
]

{ #category : 'decoding' }
PCRE2MatchTrace >> patternCharacterRangeForEvent: aPCRE2CalloutEvent [
	"Answer the character range of the next pattern item at this event."

	^ self
		  patternCharacterRangeFromStartOffset: aPCRE2CalloutEvent patternPosition
		  endOffset: aPCRE2CalloutEvent patternPosition + aPCRE2CalloutEvent nextItemLength
]

{ #category : 'decoding' }
PCRE2MatchTrace >> patternCharacterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based pattern code-unit interval to a 1-based Pharo character range."

	^ self patternInput characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset
]

{ #category : 'accessing' }
PCRE2MatchTrace >> patternInput [

	^ patternInput
]

{ #category : 'accessing' }
PCRE2MatchTrace >> resultCode [

	^ resultCode
]

{ #category : 'debugging' }
PCRE2MatchTrace >> stepForEvent: aPCRE2CalloutEvent index: stepIndex [

	| site |
	site := self calloutSiteForEvent: aPCRE2CalloutEvent.
	^ PCRE2TraceStep
		  index: stepIndex
		  event: aPCRE2CalloutEvent
		  site: site
		  kind: aPCRE2CalloutEvent eventKind
		  patternRange: (self patternCharacterRangeForEvent: aPCRE2CalloutEvent)
		  subjectPosition: (self subjectCharacterPositionAtEvent: aPCRE2CalloutEvent)
		  subjectRange: (self subjectCharacterRangeAtEvent: aPCRE2CalloutEvent)
		  captureRanges: (self captureRangesAtEvent: aPCRE2CalloutEvent)
		  mark: aPCRE2CalloutEvent mark
]

{ #category : 'debugging' }
PCRE2MatchTrace >> steps [
	"Answer one PCRE2TraceStep per callout event, in match order."

	| steps |
	steps := Array new: events size.
	1 to: events size do: [ :stepIndex | steps at: stepIndex put: (self stepForEvent: (events at: stepIndex) index: stepIndex) ].
	^ steps
]

{ #category : 'debugging' }
PCRE2MatchTrace >> stepsDo: aBlock [

	1 to: events size do: [ :stepIndex | aBlock value: (self stepForEvent: (events at: stepIndex) index: stepIndex) ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> subject [

	^ subject
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionAtEvent: aPCRE2CalloutEvent [

	^ self subjectCharacterPositionForCodeUnitOffset: aPCRE2CalloutEvent currentPosition
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionForCodeUnitOffset: codeUnitOffset [
	"Translate a zero-based subject code-unit offset to the corresponding 1-based Pharo character position."

	^ (input characterCountUpToCodeUnitOffset: codeUnitOffset) + 1
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterRangeAtEvent: aPCRE2CalloutEvent [
	"Answer the subject character range consumed by the current match attempt when this event fired."

	^ self subjectCharacterRangeFromStartOffset: aPCRE2CalloutEvent startMatch endOffset: aPCRE2CalloutEvent currentPosition
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based subject code-unit interval to a 1-based Pharo character range."

	^ input characterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset
]
