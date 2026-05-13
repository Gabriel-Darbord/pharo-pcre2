"
I describe one debugger-ready step produced from a PCRE2 match trace.

A step combines a runtime callout event with its static callout site when available, plus pretranslated pattern and subject character ranges. I keep the raw event available for native PCRE2 details, but expose stable Smalltalk-level fields that a headless debugger model or UI can consume directly.

Capture ranges preserve PCRE2 ovector order: array index 1 is the whole-match range, array index 2 is capture group 1, and so on. Unset captures are represented by nil.
"
Class {
	#name : 'PCRE2TraceStep',
	#superclass : 'Object',
	#instVars : [
		'index',
		'event',
		'site',
		'kind',
		'patternRange',
		'subjectPosition',
		'subjectRange',
		'captureRanges',
		'mark'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2TraceStep class >> index: stepIndex event: aPCRE2CalloutEvent site: aPCRE2CalloutSiteOrNil kind: aSymbol patternRange: patternInterval subjectPosition: subjectCharacterPosition subjectRange: subjectInterval captureRanges: captureRangeArray mark: markStringOrNil [

	^ self new
		  initializeIndex: stepIndex
		  event: aPCRE2CalloutEvent
		  site: aPCRE2CalloutSiteOrNil
		  kind: aSymbol
		  patternRange: patternInterval
		  subjectPosition: subjectCharacterPosition
		  subjectRange: subjectInterval
		  captureRanges: captureRangeArray
		  mark: markStringOrNil
]

{ #category : 'capture access' }
PCRE2TraceStep >> captureRangeAt: captureIndex [
	"Answer the character range for captureIndex, where 0 is the whole match, or nil when unavailable/unset."

	| storageIndex |
	storageIndex := captureIndex + 1.
	(storageIndex between: 1 and: captureRanges size) ifFalse: [ ^ nil ].
	^ captureRanges at: storageIndex
]

{ #category : 'accessing' }
PCRE2TraceStep >> captureRanges [
	"Answer ovector capture ranges in PCRE2 order. Index 1 is the whole match; index 2 is capture group 1."

	^ captureRanges
]

{ #category : 'accessing' }
PCRE2TraceStep >> event [
	"Answer the raw runtime PCRE2 callout event behind this step."

	^ event
]

{ #category : 'capture access' }
PCRE2TraceStep >> fullMatchRange [
	"Answer the whole-match character range known at this step, or nil when it is not set yet."

	^ self captureRangeAt: 0
]

{ #category : 'testing' }
PCRE2TraceStep >> hasSite [

	^ site notNil
]

{ #category : 'accessing' }
PCRE2TraceStep >> index [

	^ index
]

{ #category : 'initialization' }
PCRE2TraceStep >> initializeIndex: stepIndex event: aPCRE2CalloutEvent site: aPCRE2CalloutSiteOrNil kind: aSymbol patternRange: patternInterval subjectPosition: subjectCharacterPosition subjectRange: subjectInterval captureRanges: captureRangeArray mark: markStringOrNil [

	index := stepIndex.
	event := aPCRE2CalloutEvent.
	site := aPCRE2CalloutSiteOrNil.
	kind := aSymbol.
	patternRange := patternInterval.
	subjectPosition := subjectCharacterPosition.
	subjectRange := subjectInterval.
	captureRanges := captureRangeArray.
	mark := markStringOrNil.
	^ self
]

{ #category : 'testing' }
PCRE2TraceStep >> isBacktrack [

	^ kind = #backtrack
]

{ #category : 'testing' }
PCRE2TraceStep >> isProgress [

	^ kind = #progress
]

{ #category : 'testing' }
PCRE2TraceStep >> isStartMatch [

	^ kind = #startMatch
]

{ #category : 'accessing' }
PCRE2TraceStep >> kind [
	"Answer the coarse debugger transition: #startMatch, #progress, or #backtrack."

	^ kind
]

{ #category : 'accessing' }
PCRE2TraceStep >> mark [

	^ mark
]

{ #category : 'accessing' }
PCRE2TraceStep >> patternRange [
	"Answer the 1-based Pharo character range for the next pattern item reported by PCRE2 at this step."

	^ patternRange
]

{ #category : 'printing' }
PCRE2TraceStep >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: index;
		nextPutAll: ', ';
		print: kind;
		nextPutAll: ', pattern ';
		print: patternRange;
		nextPutAll: ', subject ';
		print: subjectPosition.
	site ifNotNil: [
		aStream
			nextPutAll: ', callout ';
			print: site number ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
PCRE2TraceStep >> site [
	"Answer the static callout site matched to the event, or nil if none was found."

	^ site
]

{ #category : 'accessing' }
PCRE2TraceStep >> subjectPosition [

	^ subjectPosition
]

{ #category : 'accessing' }
PCRE2TraceStep >> subjectRange [
	"Answer the 1-based Pharo character range consumed by the current match attempt at this step."

	^ subjectRange
]
