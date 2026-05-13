"
I describe one instrumented PCRE2 match attempt.

A trace is produced by compiling a temporary debug matcher with automatic callouts, running a non-JIT match, and collecting runtime PCRE2CalloutEvent snapshots. The original matcher is not mutated.

I am intentionally a data object for now: UI/debugger tools can use my static callout sites, runtime events, match result, and UTF-8 byte-to-character helpers to build a step-by-step explanation.
"
Class {
	#name : 'PCRE2MatchTrace',
	#superclass : 'Object',
	#instVars : [
		'pattern',
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
PCRE2MatchTrace class >> pattern: patternString subject: subjectObject input: aPCRE2UTF8Input calloutSites: calloutSiteArray events: eventArray match: aMatchOrNil resultCode: anInteger [

	^ self new
		  initializePattern: patternString
		  subject: subjectObject
		  input: aPCRE2UTF8Input
		  calloutSites: calloutSiteArray
		  events: eventArray
		  match: aMatchOrNil
		  resultCode: anInteger
]

{ #category : 'accessing' }
PCRE2MatchTrace >> calloutSites [

	^ calloutSites
]

{ #category : 'accessing' }
PCRE2MatchTrace >> events [

	^ events
]

{ #category : 'initialization' }
PCRE2MatchTrace >> initializePattern: patternString subject: subjectObject input: aPCRE2UTF8Input calloutSites: calloutSiteArray events: eventArray match: aMatchOrNil resultCode: anInteger [

	pattern := patternString.
	subject := subjectObject.
	input := aPCRE2UTF8Input.
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
	"Answer whether the complete match spans the full UTF-8 subject bytes."

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

{ #category : 'accessing' }
PCRE2MatchTrace >> pattern [

	^ pattern
]

{ #category : 'accessing' }
PCRE2MatchTrace >> resultCode [

	^ resultCode
]

{ #category : 'accessing' }
PCRE2MatchTrace >> subject [

	^ subject
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionAtEvent: aPCRE2CalloutEvent [
	"Answer the 1-based Pharo character position where this callout event occurred."

	^ self subjectCharacterPositionForByteOffset:
		  aPCRE2CalloutEvent currentPosition
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterPositionForByteOffset: byteOffset [
	"Translate a zero-based UTF-8 byte offset to the corresponding 1-based Pharo character position."

	^ (input characterCountUpToByteOffset: byteOffset) + 1
]

{ #category : 'decoding' }
PCRE2MatchTrace >> subjectCharacterRangeFromStartOffset: zeroBasedStartOffset endOffset: exclusiveEndOffset [
	"Translate PCRE2's zero-based UTF-8 byte offsets to a 1-based Pharo character range."

	^ input
		  characterRangeFromStartOffset: zeroBasedStartOffset
		  endOffset: exclusiveEndOffset
]
