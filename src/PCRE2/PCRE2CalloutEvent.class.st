"
I am a snapshot of a runtime PCRE2 callout, explicit such as (?C1) or automatic. I copy the match state and callout strings out of the native callout block, so I stay valid after the callback returns.

My offsets are raw PCRE2 code-unit offsets in the prepared subject and pattern, left untranslated so that a debugger sees the native positions. `eventKind` classifies me as a start match, progress, or backtrack step.
"
Class {
	#name : 'PCRE2CalloutEvent',
	#superclass : 'Object',
	#instVars : [
		'version',
		'number',
		'captureTop',
		'captureLast',
		'offsets',
		'mark',
		'subjectLength',
		'startMatch',
		'currentPosition',
		'patternPosition',
		'nextItemLength',
		'stringOffset',
		'stringLength',
		'string',
		'flags'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2CalloutEvent >> captureLast [

	^ captureLast
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> captureTop [

	^ captureTop
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> currentPosition [
	"Answer the current subject position as a zero-based PCRE2 code-unit offset."

	^ currentPosition
]

{ #category : 'testing' }
PCRE2CalloutEvent >> eventKind [

	self isBacktrack ifTrue: [ ^ #backtrack ].
	self isStartMatch ifTrue: [ ^ #startMatch ].
	^ #progress
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> flags [

	^ flags
]

{ #category : 'testing' }
PCRE2CalloutEvent >> hasString [

	^ string isNotNil
]

{ #category : 'initialization' }
PCRE2CalloutEvent >> initializeSite: site captures: values captureLast: lastCapture start: start position: current subjectLength: size flags: bits mark: markName [

	version := 2.
	number := site number.
	patternPosition := site patternPosition.
	nextItemLength := site nextItemLength.
	string := site string.
	stringLength := site stringLength.
	stringOffset := site stringOffset.
	captureTop := 1.
	1 to: values size // 2 - 1 do: [ :index | (values at: index * 2 + 2) ~= PCRE2 unsetOffset ifTrue: [ captureTop := index + 1 ] ].
	offsets := values first: captureTop * 2.
	captureLast := lastCapture.
	startMatch := start.
	currentPosition := current.
	subjectLength := size.
	flags := bits.
	mark := markName
]

{ #category : 'testing' }
PCRE2CalloutEvent >> isAutomatic [
	"Answer whether this event came from PCRE2_AUTO_CALLOUT rather than an explicit (?C...) item."

	^ number = PCRE2 automaticCalloutNumber and: [ string isNil ]
]

{ #category : 'testing' }
PCRE2CalloutEvent >> isBacktrack [

	^ (flags bitAnd: PCRE2 calloutBacktrack) ~~ 0
]

{ #category : 'testing' }
PCRE2CalloutEvent >> isStartMatch [

	^ (flags bitAnd: PCRE2 calloutStartMatch) ~~ 0
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> mark [

	^ mark
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> nextItemLength [
	"Answer the length of the next pattern item in PCRE2 code units."

	^ nextItemLength
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> number [

	^ number
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> offsets [
	"Answer raw zero-based PCRE2 code-unit ovector offsets visible at this callout."

	^ offsets
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> offsetsAt: pairIndex [
	"Answer the requested zero-based {start. exclusiveEnd} PCRE2 code-unit ovector pair."

	| index |
	index := 2 * (pairIndex - 1).
	^ {
		  (offsets at: index + 1).
		  (offsets at: index + 2) }
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> patternPosition [
	"Answer the current pattern position as a zero-based PCRE2 code-unit offset."

	^ patternPosition
]

{ #category : 'printing' }
PCRE2CalloutEvent >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: patternPosition;
		nextPutAll: ', ';
		print: currentPosition;
		nextPutAll: ', ';
		print: number.
	string ifNotNil: [
			aStream
				nextPutAll: ', ';
				print: string ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> startMatch [
	"Answer the subject start position for this match attempt as a zero-based PCRE2 code-unit offset."

	^ startMatch
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> string [

	^ string
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> stringLength [
	"Answer the callout string length in PCRE2 code units."

	^ stringLength
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> stringOffset [
	"Answer the callout string's pattern position as a zero-based PCRE2 code-unit offset."

	^ stringOffset
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> subjectLength [
	"Answer the prepared subject length in PCRE2 code units."

	^ subjectLength
]

{ #category : 'accessing' }
PCRE2CalloutEvent >> version [

	^ version
]
