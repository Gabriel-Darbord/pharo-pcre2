"
I am a snapshot of a substitution callout, taken after a replacement is processed and before it is accepted. My offsets and texts are copied during the callback, so I can be kept.

Offsets are zero-based code units of the matcher width: `offsets` is the ovector of the match in the subject, and `outputOffsets` locates the replacement in the output.
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
	#category : 'PCRE2-Substitution',
	#package : 'PCRE2-Substitution'
}

{ #category : 'initialization' }
PCRE2SubstitutionCalloutEvent >> match: match replacement: text count: count outputStart: start length: length [

	version := 0.
	substitutionCount := count.
	offsets := match offsets copy.
	ovectorCount := match ovectorCount.
	matchedText := match readMatch.
	replacementText := text.
	outputOffsets := {
		                 start.
		                 (start + length) }
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> matchedText [

	^ matchedText
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> offsets [

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

	^ outputOffsets
]

{ #category : 'accessing' }
PCRE2SubstitutionCalloutEvent >> ovectorCount [

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
