"
I describe one step of a match trace: a runtime callout event, its static callout site when known, and the pattern and subject character ranges, translated in advance.

Capture ranges follow ovector order: index 1 is the whole match, index 2 is group 1, and so on. An unset capture is nil.
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
	#category : 'PCRE2-Trace',
	#package : 'PCRE2-Trace'
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

	^ captureRanges
]

{ #category : 'accessing' }
PCRE2TraceStep >> event [

	^ event
]

{ #category : 'capture access' }
PCRE2TraceStep >> fullMatchRange [
	"Answer the whole-match character range known at this step, or nil when it is not set yet."

	^ self captureRangeAt: 0
]

{ #category : 'testing' }
PCRE2TraceStep >> hasSite [

	^ site isNotNil
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
	mark := markStringOrNil
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
	"Answer the character range of the next pattern item at this step."

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
