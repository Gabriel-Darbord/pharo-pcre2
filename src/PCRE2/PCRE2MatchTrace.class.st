"
I describe one instrumented PCRE2 match attempt.

A trace is produced by compiling a temporary debug matcher with automatic callouts, running a non-JIT match, and collecting runtime PCRE2CalloutEvent snapshots. The original matcher is not mutated.

I keep the data used by UI and debugger tools: static callout sites, runtime events, match result, code-unit-to-character helpers, and event-to-site correlation methods.

My steps API builds PCRE2TraceStep objects that pretranslate pattern and subject positions, capture ranges, and marks for a debugger or trace viewer.
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
	#category : 'PCRE2',
	#package : 'PCRE2'
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
	"Answer the static callout site corresponding to a runtime event, or nil if none is known."

	^ self calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: [ nil ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> calloutSiteForEvent: aPCRE2CalloutEvent ifAbsent: absentBlock [
	"Answer the static callout site corresponding to a runtime event."

	^ calloutSites
		  detect: [ :site | site matchesEvent: aPCRE2CalloutEvent ]
		  ifNone: absentBlock
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
		ranges at: pairIndex put: ((self offsetPairIsUnset: offsetPair)
				 ifTrue: [ nil ]
				 ifFalse: [
					 self
						 subjectCharacterRangeFromStartOffset: offsetPair first
						 endOffset: offsetPair second ]) ].
	^ ranges
]

{ #category : 'accessing' }
PCRE2MatchTrace >> events [

	^ events
]

{ #category : 'enumerating' }
PCRE2MatchTrace >> eventsDo: aBlock [
	"Evaluate aBlock with each runtime callout event in match order."

	events do: aBlock
]

{ #category : 'enumerating' }
PCRE2MatchTrace >> eventsWithSitesDo: aBlock [
	"Evaluate aBlock with each runtime event and its matching static callout site, if any."

	events do: [ :event |
		aBlock value: event value: (self calloutSiteForEvent: event) ]
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
	resultCode := anInteger.
	^ self
]

{ #category : 'accessing' }
PCRE2MatchTrace >> input [

	^ input
]

{ #category : 'testing' }
PCRE2MatchTrace >> isFullMatch [
	"Answer whether the complete match spans the prepared subject input."

	self isMatch ifFalse: [ ^ false ].
	match offsetsDo: [ :start :end |
		^ start = 1 and: [ end = input size ] ].
	^ false
]

{ #category : 'testing' }
PCRE2MatchTrace >> isMatch [
	"Answer whether the traced attempt produced a complete match."

	^ match notNil and: [ match isComplete ]
]

{ #category : 'testing' }
PCRE2MatchTrace >> isPartial [
	"Answer whether the traced attempt produced a partial match."

	^ match notNil and: [ match isPartial ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> match [

	^ match
]

{ #category : 'accessing' }
PCRE2MatchTrace >> matchedString [
	"Answer the complete matched substring, or nil when the trace did not match."

	^ match ifNotNil: [ match readMatch ]
]

{ #category : 'private' }
PCRE2MatchTrace >> offsetPairIsUnset: offsetPair [
	"Answer whether a PCRE2 ovector pair contains PCRE2_UNSET."

	^ offsetPair first = PCRE2 unsetOffset or: [
		  offsetPair second = PCRE2 unsetOffset ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> pattern [

	^ pattern
]

{ #category : 'decoding' }
PCRE2MatchTrace >> patternCharacterRangeForEvent: aPCRE2CalloutEvent [
	"Answer the Pharo character range for the pattern item associated with this event."

	^ self
		  patternCharacterRangeFromStartOffset:
		  aPCRE2CalloutEvent patternPosition
		  endOffset:
		  aPCRE2CalloutEvent patternPosition
		  + aPCRE2CalloutEvent nextItemLength
]

{ #category : 'decoding' }
PCRE2MatchTrace >> patternCharacterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based pattern code-unit interval to a 1-based Pharo character range."

	^ self patternInput
		  characterRangeFromStartOffset: zeroBasedStartOffset
		  endOffset: exclusiveEndOffset
]

{ #category : 'accessing' }
PCRE2MatchTrace >> patternInput [
	"Answer the prepared pattern input whose code-unit offsets match the traced matcher width."

	^ patternInput
]

{ #category : 'accessing' }
PCRE2MatchTrace >> resultCode [

	^ resultCode
]

{ #category : 'debugging' }
PCRE2MatchTrace >> stepForEvent: aPCRE2CalloutEvent index: stepIndex [
	"Answer a debugger-ready step for one runtime callout event."

	| site |
	site := self calloutSiteForEvent: aPCRE2CalloutEvent.
	^ PCRE2TraceStep
		  index: stepIndex
		  event: aPCRE2CalloutEvent
		  site: site
		  kind: aPCRE2CalloutEvent eventKind
		  patternRange:
		  (self patternCharacterRangeForEvent: aPCRE2CalloutEvent)
		  subjectPosition:
		  (self subjectCharacterPositionAtEvent: aPCRE2CalloutEvent)
		  subjectRange:
		  (self subjectCharacterRangeAtEvent: aPCRE2CalloutEvent)
		  captureRanges: (self captureRangesAtEvent: aPCRE2CalloutEvent)
		  mark: aPCRE2CalloutEvent mark
]

{ #category : 'debugging' }
PCRE2MatchTrace >> steps [
	"Answer debugger-ready steps derived from the runtime callout events."

	| steps |
	steps := Array new: events size.
	1 to: events size do: [ :stepIndex |
		steps
			at: stepIndex
			put: (self stepForEvent: (events at: stepIndex) index: stepIndex) ].
	^ steps
]

{ #category : 'debugging' }
PCRE2MatchTrace >> stepsDo: aBlock [
	"Evaluate aBlock with each debugger-ready step in match order."

	1 to: events size do: [ :stepIndex |
		aBlock value:
			(self stepForEvent: (events at: stepIndex) index: stepIndex) ]
]

{ #category : 'accessing' }
PCRE2MatchTrace >> subject [

	^ subject
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionAtEvent: aPCRE2CalloutEvent [
	"Answer the 1-based Pharo character position for the event's current subject code-unit offset."

	^ self subjectCharacterPositionForCodeUnitOffset:
		  aPCRE2CalloutEvent currentPosition
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionForCodeUnitOffset: codeUnitOffset [
	"Translate a zero-based subject code-unit offset to the corresponding 1-based Pharo character position."

	^ (input characterCountUpToCodeUnitOffset: codeUnitOffset) + 1
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterRangeAtEvent: aPCRE2CalloutEvent [
	"Answer the subject character range consumed by the current match attempt when this event fired."

	^ self
		  subjectCharacterRangeFromStartOffset:
		  aPCRE2CalloutEvent startMatch
		  endOffset: aPCRE2CalloutEvent currentPosition
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based subject code-unit interval to a 1-based Pharo character range."

	^ input
		  characterRangeFromStartOffset: zeroBasedStartOffset
		  endOffset: exclusiveEndOffset
]
