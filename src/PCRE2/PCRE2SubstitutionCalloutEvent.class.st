"
I am a snapshot of a PCRE2 substitution callout.

PCRE2 creates me after a replacement has been processed by `pcre2_substitute_*`, before the replacement is finally accepted. I copy the native offsets and the affected input/output text while the callback is running, so clients can safely keep events afterwards.

Offsets are raw PCRE2 code-unit offsets for the matcher width that produced the event. The full-match offsets come from the current match ovector in the original subject. The output offsets identify the processed replacement in the output buffer.
"
Class {
	#name : 'PCRE2SubstitutionCalloutEvent',
	#superclass : 'Object',
	#instVars : [
		'version',
		'substitutionCount',
		'offsets',
		'outputOffsets',
		'ovectorCount',
		'matchedText',
		'replacementText'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> matchedText [
	"Answer the subject substring matched for this substitution."

	^ matchedText
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> offsets [
	"Answer raw zero-based PCRE2 code-unit ovector offsets for the current match."

	^ offsets
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> offsetsAt: pairIndex [
	"Answer the requested zero-based {start. exclusiveEnd} PCRE2 code-unit ovector pair."

	| index |
	index := 2 * (pairIndex - 1).
	^ {
		  (offsets at: index + 1).
		  (offsets at: index + 2) }
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> outputOffsets [
	"Answer raw zero-based PCRE2 code-unit offsets of the processed replacement in the output buffer."

	^ outputOffsets
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> ovectorCount [
	"Answer the number of ovector pairs available in this event."

	^ ovectorCount
]

{ #category : 'printing' }
PCRE2SubstitutionCalloutEvent >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		print: substitutionCount;
		nextPutAll: ', ';
		print: matchedText;
		nextPutAll: ' -> ';
		print: replacementText;
		nextPut: $)
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> replacementText [
	"Answer the processed replacement text before the callout accepts or rejects it."

	^ replacementText
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> substitutionCount [
	"Answer the one-based substitution number reported by PCRE2."

	^ substitutionCount
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> version [

	^ version
]
