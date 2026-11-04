"
What the two structural start optimizations need to know about where in the pattern they are looking. A leading dot star only counts outside atomic groups and assertions, in a group nothing refers back to, and in a pattern free of (*PRUNE) and (*SKIP), since each lets a later attempt find what the first would not. Walking into a group answers a new analysis, so a branch that fails leaves nothing behind for the next.
"
Class {
	#name : 'PCRE2StartAnalysis',
	#superclass : 'Object',
	#instVars : [
		'backreferences',
		'pruneOrSkip',
		'dotStarAnchor',
		'enclosingGroups',
		'atomicDepth',
		'inAssertion'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'instance creation' }
PCRE2StartAnalysis class >> backreferences: map pruneOrSkip: aBoolean dotStarAnchor: enabled [

	^ self new setBackreferences: map pruneOrSkip: aBoolean dotStarAnchor: enabled
]

{ #category : 'accessing' }
PCRE2StartAnalysis class >> bitFor: index [
	"The bit PCRE2 gives one group number. Only the first 31 get one of their own; everything above shares the lowest."

	^ index < 32
		  ifTrue: [ 1 bitShift: index ]
		  ifFalse: [ 1 ]
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> allowsLeadingDotStar [
	"Whether a dot star at the start of this branch still says where a match can begin."

	^ dotStarAnchor and: [
		  (enclosingGroups bitAnd: backreferences) = 0 and: [ atomicDepth = 0 and: [ pruneOrSkip not and: [ inAssertion not ] ] ] ]
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> atomicDepth: anInteger [

	atomicDepth := anInteger
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> enclosingGroups: map [

	enclosingGroups := map
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> inAssertion: aBoolean [

	inAssertion := aBoolean
]

{ #category : 'initialization' }
PCRE2StartAnalysis >> setBackreferences: map pruneOrSkip: aBoolean dotStarAnchor: enabled [

	backreferences := map.
	pruneOrSkip := aBoolean.
	dotStarAnchor := enabled.
	enclosingGroups := 0.
	atomicDepth := 0.
	inAssertion := false
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> withinAssertion [

	^ self copy inAssertion: true
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> withinAtomicGroup [

	^ self copy atomicDepth: atomicDepth + 1
]

{ #category : 'accessing' }
PCRE2StartAnalysis >> withinGroup: index [

	^ self copy enclosingGroups: (enclosingGroups bitOr: (self class bitFor: index))
]
