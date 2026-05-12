"
I contain match data resulting from the execution of a compiled pattern.
Library users do not normally interact with my instances.
"
Class {
	#name : 'PCRE2Match',
	#superclass : 'PCRE2Object',
	#instVars : [
		'count',
		'isPersistent',
		'offsets',
		'mark',
		'startIndex',
		'subject',
		'decoder'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'persistence' }
PCRE2Match >> bePersistent [
	"Update myself to be persistent: copy the external object to local memory"

	self count.
	offsets isArray ifFalse: [ "copy external data into local memory"
		self offsets ].
	"TODO: copy named groups"
	self free.
	handle beNull.
	isPersistent := true
]

{ #category : 'accessing' }
PCRE2Match >> count [
	"Number of subpatterns plus one for the whole pattern"

	^ count ifNil: [ count := self getCount ]
]

{ #category : 'private' }
PCRE2Match >> count: anInteger [
	"Only used by the regex matcher after a match"

	count := anInteger
]

{ #category : 'accessing' }
PCRE2Match >> decoder [

	^ decoder
]

{ #category : 'accessing' }
PCRE2Match >> endOffsetAt: pairIndex [
	"Return the zero-based exclusive end offset for the requested ovector pair. PCRE2 stores ovector entries as PCRE2_SIZE values; keep the 32/64-bit primitive fast paths because this accessor is used by match-result readers."

	| index wordSize |
	index := 2 * (pairIndex - 1) + 1. "to 0-based"
	offsets isArray ifTrue: [ ^ offsets at: index + 1 ].

	offsets ifNil: [ offsets := self getOffsets ].
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [ ^ offsets uint64AtOffset: 8 * index ].
	wordSize == 4 ifTrue: [ ^ offsets uint32AtOffset: 4 * index ].
	^ offsets platformSizeTAt: wordSize * index + 1
]

{ #category : 'private' }
PCRE2Match >> ensureSubjectAvailable [

	subject ifNil: [
		self error:
			'This match does not remember a subject; use readMatch: or readMatches: with an explicit subject' ]
]

{ #category : 'external resource management' }
PCRE2Match >> free [

	self ffiCall: #(void pcre2_match_data_free_8(self))
]

{ #category : 'private' }
PCRE2Match >> getCount [
	"This function returns the number of pairs of offsets in the ovector that forms part of the given match data block"

	self ffiCall: #(int pcre2_get_ovector_count_8(self))
]

{ #category : 'private' }
PCRE2Match >> getMark [
	"After a call of match() that was passed the match block that is this function's argument,
	this function returns a pointer to the last (*MARK), (*PRUNE), or (*THEN) name that was
	encountered during the matching process. If no name is available, NULL is returned."

	self ffiCall: #(char *pcre2_get_mark_8(self))
]

{ #category : 'private' }
PCRE2Match >> getOffsets [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_8(self))
]

{ #category : 'private' }
PCRE2Match >> getStartIndex [

	self ffiCall: #(size_t pcre2_get_startchar_8(self))
]

{ #category : 'initialization' }
PCRE2Match >> initialize [

	isPersistent := false
]

{ #category : 'testing' }
PCRE2Match >> isPersistent [

	^ isPersistent
]

{ #category : 'enumerating' }
PCRE2Match >> lastMatchIndex [
	"Return the zero-based exclusive end offset of the full match. This is ovector[1], stored by PCRE2 as PCRE2_SIZE/size_t, so read it with the same fixed-width fast paths used by the other ovector accessors."

	| wordSize |
	^ isPersistent
		  ifTrue: [ offsets at: 2 ]
		  ifFalse: [
			  offsets ifNil: [ offsets := self getOffsets ].
			  wordSize := ExternalAddress wordSize.
			  wordSize == 8 ifTrue: [ ^ offsets uint64AtOffset: 8 ].
			  wordSize == 4 ifTrue: [ ^ offsets uint32AtOffset: 4 ].
			  offsets platformSizeTAt: wordSize + 1 ]
]

{ #category : 'accessing' }
PCRE2Match >> mark [

	^ mark ifNil: [ mark := self getMark ifEmpty: [ nil ] ]
]

{ #category : 'enumerating' }
PCRE2Match >> offsets [
	"Returns the array containing offset pairs for the match and captured substrings. (DO NOT MODIFY IT!)
	The start offsets are at odd indexes, and the corresponding end offsets are at the following even indexes.
	The first pair identifies the part of the subject string that was matched by the entire pattern.
	Subsequent pairs identify the captured substrings."

	| copy index |
	"use this opportunity to copy external data locally if not already done, to ensure persistence"
	offsets isArray ifTrue: [ ^ offsets ].
	copy := Array new: 2 * self count.
	index := 0.
	self offsetsDo: [ :start :end |
		copy at: index + 1 put: start.
		copy at: (index := index + 2) put: end ].
	^ offsets := copy
]

{ #category : 'accessing' }
PCRE2Match >> offsetsAt: pairIndex [
	"Return the requested raw ovector pair as zero-based {start. exclusiveEnd}. PCRE2 stores each entry as PCRE2_SIZE; the fixed-width branches are intentional hot-path reads, with platformSizeTAt: kept only as an unusual-platform fallback."

	| index wordSize |
	index := 2 * (pairIndex - 1). "to 0-based"
	offsets isArray ifTrue: [
		^ {
			  (offsets at: index + 1).
			  (offsets at: index + 2) } ].

	offsets ifNil: [ offsets := self getOffsets ].
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [
		^ {
			  (offsets uint64AtOffset: 8 * index).
			  (offsets uint64AtOffset: 8 * (index + 1)) } ].
	wordSize == 4 ifTrue: [
		^ {
			  (offsets uint32AtOffset: 4 * index).
			  (offsets uint32AtOffset: 4 * (index + 1)) } ].
	^ {
		  (offsets platformSizeTAt: wordSize * index + 1).
		  (offsets platformSizeTAt: wordSize * (index + 1) + 1) }
]

{ #category : 'enumerating' }
PCRE2Match >> offsetsDo: aBlock [
	"Iterate translated offset pairs: starts become 1-based inclusive indexes, while PCRE2's zero-based exclusive ends already have the same numeric value as Pharo inclusive ends. The fixed-width 32/64-bit loops are intentional: platformSizeTAt: is portable but much slower in this hot path."

	| wordSize |
	offsets isArray ifTrue: [ "offsets have already been copied to a local array"
		1 to: count by: 2 do: [ :i |
		aBlock value: (offsets at: i) value: (offsets at: i + 1) ].
		^ self ].

	offsets ifNil: [ offsets := self getOffsets ]. "table containing pairs of 0-based indexes"
	wordSize := ExternalAddress wordSize.

	wordSize == 8 ifTrue: [
		1 to: self count do: [ :i |
			| start end |
			start := (offsets uint64AtOffset: 16 * (i - 1)) + 1.
			end := offsets uint64AtOffset: 16 * i - 8.
			aBlock value: start value: end ].
		^ self ].

	wordSize == 4 ifTrue: [
		1 to: self count do: [ :i |
			| start end |
			start := (offsets uint32AtOffset: 8 * (i - 1)) + 1.
			end := offsets uint32AtOffset: 8 * i - 4.
			aBlock value: start value: end ].
		^ self ].

	1 to: self count do: [ :i |
		| start end |
		start := (offsets platformSizeTAt: 2 * wordSize * (i - 1) + 1) + 1.
		end := offsets platformSizeTAt: wordSize * (2 * i - 1) + 1.
		aBlock value: start value: end ]
]

{ #category : 'accessing' }
PCRE2Match >> ovectorCount [
	"Return the number of offset pairs available in this match data block."

	^ self getCount
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatch [
	"Returns the first matched substring from the remembered subject."

	| bytes |
	self ensureSubjectAvailable.
	bytes := self readMatch: subject.
	^ decoder
		  ifNil: [ bytes ]
		  ifNotNil: [ bytes ifNotNil: [ decoder decodeBytes: bytes ] ]
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatch: subject [
	"Returns the matching subcollection of a pattern applied to subject"

	self offsetsDo: [ :start :end | ^ subject copyFrom: start to: end ].
	^ nil
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatches [
	"Returns all matched substrings from the remembered subject."

	self ensureSubjectAvailable.
	^ decoder
		  ifNil: [ self readMatches: subject ]
		  ifNotNil: [ self readMatches: subject decodeWith: decoder ]
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatches: subject [
	"Returns the matching subcollections of a pattern and its groups applied to subject"

	| matches index |
	matches := Array new: self count.
	index := 0.
	self offsetsDo: [ :start :end |
		matches
			at: (index := index + 1)
			put: (subject copyFrom: start to: end) ].
	^ matches
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatches: subject decodeWith: decoder [
	"Returns the decoded matching subcollections of a pattern and its groups applied to subject"

	| matches index |
	matches := Array new: self count.
	index := 0.
	self offsetsDo: [ :start :end |
		matches
			at: (index := index + 1)
			put: (decoder decodeBytes: (subject copyFrom: start to: end)) ].
	^ matches
]

{ #category : 'initialization' }
PCRE2Match >> reset [

	isPersistent := false.
	startIndex := nil.
	offsets := nil.
	mark := nil.
	subject := nil.
	decoder := nil
]

{ #category : 'accessing' }
PCRE2Match >> startIndex [
	"Available after a match, answered as a 1-based code-unit index."

	^ startIndex ifNil: [ startIndex := self getStartIndex + 1 ]
]

{ #category : 'accessing' }
PCRE2Match >> startOffsetAt: pairIndex [
	"Return the zero-based inclusive start offset for the requested ovector pair. PCRE2 exposes the ovector as PCRE2_SIZE*, mapped here to size_t; the 32/64-bit branches deliberately use primitive fixed-width reads because platformSizeTAt: is too slow for this hot path."

	| index wordSize |
	index := 2 * (pairIndex - 1). "to 0-based"
	offsets isArray ifTrue: [ ^ offsets at: index + 1 ].

	offsets ifNil: [ offsets := self getOffsets ].
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [ ^ offsets uint64AtOffset: 8 * index ].
	wordSize == 4 ifTrue: [ ^ offsets uint32AtOffset: 4 * index ].
	^ offsets platformSizeTAt: wordSize * index + 1
]

{ #category : 'accessing' }
PCRE2Match >> subject [

	^ subject
]

{ #category : 'accessing' }
PCRE2Match >> subject: aByteArray decoder: aDecoder [
	"Remember the encoded subject used for this match so callers can query the result later."

	subject := aByteArray.
	decoder := aDecoder
]
