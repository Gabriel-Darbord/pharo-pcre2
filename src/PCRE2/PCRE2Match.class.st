"
Abstract superclass for PCRE2 match data.

Concrete subclasses bind the native match-data accessors for PCRE2's 8-bit, 16-bit, and 32-bit APIs. This class stores shared result state: result code, offsets, remembered subject/input, decoder, named-capture metadata, and persistence state.

Use match objects to inspect captures after matching. Persistent matches copy native offset data into Pharo memory and release the native match-data handle.
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
		'decoder',
		'input',
		'nameTable',
		'resultCode'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'persistence' }
PCRE2Match >> bePersistent [
	"Copy native offset data into Pharo memory and release my external match-data handle. Named-group metadata is already Pharo-side state."

	self count.
	offsets isArray ifFalse: [ "copy external data into local memory"
		self offsets ].
	self free.
	handle beNull.
	isPersistent := true
]

{ #category : 'private' }
PCRE2Match >> captureIndexesNamed: groupName [
	"Answer all capture group numbers associated with groupName. Duplicate names are preserved in capture order."

	| indexes |
	indexes := OrderedCollection new.
	self namedGroups keysAndValuesDo: [ :captureIndex :name |
		name = groupName ifTrue: [ indexes add: captureIndex ] ].
	^ indexes asArray
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

	(input isNil and: [ subject isNil ]) ifTrue: [
		self error:
			'This match does not remember a subject; use readMatch: or readMatches: with an explicit subject' ]
]

{ #category : 'external resource management' }
PCRE2Match >> free [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getCount [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getMark [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getOffsets [
	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getStartIndex [
	^ self subclassResponsibility
]

{ #category : 'group access' }
PCRE2Match >> groupAt: groupNumber [
	"Answer the matched text for groupNumber, where 0 is the whole match and 1 is the first capture. Answer nil for an optional capture group that did not participate in the match."

	| pair |
	(groupNumber isInteger and: [ groupNumber >= 0 ]) ifFalse: [
		self error: 'Group number must be a non-negative integer' ].
	groupNumber >= self count ifTrue: [ ^ nil ].

	self ensureSubjectAvailable.
	pair := self offsetsAt: groupNumber + 1.
	(self isUnsetOffset: pair first) ifTrue: [ ^ nil ].
	^ self readSubjectFrom: pair first + 1 to: pair second
]

{ #category : 'group access' }
PCRE2Match >> groupNamed: groupName [
	"Answer the matched text for groupName, or nil when the name is absent or the group did not participate. For duplicate names, answer the first participating capture."

	^ self groupNamed: groupName ifAbsent: [ nil ]
]

{ #category : 'group access' }
PCRE2Match >> groupNamed: groupName ifAbsent: absentBlock [
	"Answer the matched text for groupName. Evaluate absentBlock when the pattern has no such named group. If the name exists but the group did not participate, answer nil."

	| indexes |
	indexes := self captureIndexesNamed: groupName.
	indexes isEmpty ifTrue: [ ^ absentBlock value ].
	indexes do: [ :captureIndex |
		| group |
		group := self groupAt: captureIndex.
		group ifNotNil: [ ^ group ] ].
	^ nil
]

{ #category : 'group access' }
PCRE2Match >> groupsByName [
	"Answer a Dictionary mapping each named capture to its matched text. For duplicate names, use the first participating capture, matching groupNamed:."

	| groups |
	groups := Dictionary new.
	self namedGroups do: [ :name |
		(name notNil and: [ (groups includesKey: name) not ]) ifTrue: [
			groups at: name put: (self groupNamed: name) ] ].
	^ groups
]

{ #category : 'group access' }
PCRE2Match >> groupsNamed: groupName [
	"Answer all matched texts for groupName in capture order. Duplicate names are preserved; optional captures that did not participate answer nil in their position."

	^ (self captureIndexesNamed: groupName) collect: [ :captureIndex |
		  self groupAt: captureIndex ]
]

{ #category : 'initialization' }
PCRE2Match >> initialize [

	isPersistent := false
]

{ #category : 'accessing' }
PCRE2Match >> input [

	^ input
]

{ #category : 'accessing' }
PCRE2Match >> input: aPreparedInput [
	"Remember the prepared input used for this match so callers can query decoded results later."

	input := aPreparedInput.
	subject := aPreparedInput bytes.
	decoder := aPreparedInput decoder
]

{ #category : 'testing' }
PCRE2Match >> isComplete [
	"Answer whether PCRE2 returned a complete match result."

	^ resultCode notNil and: [ resultCode > 0 ]
]

{ #category : 'testing' }
PCRE2Match >> isPartial [
	"Answer whether PCRE2 returned PCRE2_ERROR_PARTIAL for this result."

	^ resultCode = PCRE2 errorPartial
]

{ #category : 'testing' }
PCRE2Match >> isPersistent [

	^ isPersistent
]

{ #category : 'private' }
PCRE2Match >> isUnsetOffset: anInteger [
	"Answer whether anInteger is PCRE2_UNSET."

	^ anInteger = self unsetOffset
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

{ #category : 'accessing' }
PCRE2Match >> namedGroups [
	"Answer a sparse Array mapping PCRE2 capture group numbers to their names.
	Capture group 1 is the first parenthesized group; group 0 is the whole match and is not named."

	^ nameTable ifNil: [ #(  ) ]
]

{ #category : 'private' }
PCRE2Match >> namedGroups: aNameTable [
	"Remember the matcher's named-capture table for later group lookup."

	nameTable := aNameTable
]

{ #category : 'enumerating' }
PCRE2Match >> offsets [
	"Returns the raw PCRE2 offset pairs for the match and captured substrings. (DO NOT MODIFY IT!)
	The start offsets are at odd indexes, and the corresponding exclusive end offsets are at the following even indexes.
	The first pair identifies the part of the subject string that was matched by the entire pattern.
	Subsequent pairs identify the captured substrings."

	| copy pair |
	"Use this opportunity to copy external data locally if not already done, preserving PCRE2's zero-based offset convention."
	offsets isArray ifTrue: [ ^ offsets ].
	copy := Array new: 2 * self count.
	1 to: self count do: [ :pairIndex |
		pair := self offsetsAt: pairIndex.
		copy at: 2 * pairIndex - 1 put: pair first.
		copy at: 2 * pairIndex put: pair second ].
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
		1 to: self count do: [ :pairIndex |
			| index |
			index := 2 * (pairIndex - 1).
			aBlock
				value: (offsets at: index + 1) + 1
				value: (offsets at: index + 2) ].
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
	input ifNotNil: [
		self offsetsDo: [ :start :end | ^ input readFrom: start to: end ].
		^ nil ].
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

	| index matches |
	self ensureSubjectAvailable.
	input ifNotNil: [
		matches := Array new: self count.
		index := 0.
		self offsetsDo: [ :start :end |
			matches
				at: (index := index + 1)
				put: (input readFrom: start to: end) ].
		^ matches ].
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

{ #category : 'private' }
PCRE2Match >> readSubjectFrom: start to: end [
	"Answer remembered subject content from start to end, decoding when needed."

	| bytes |
	input ifNotNil: [ ^ input readFrom: start to: end ].
	bytes := subject copyFrom: start to: end.
	^ decoder ifNil: [ bytes ] ifNotNil: [ decoder decodeBytes: bytes ]
]

{ #category : 'initialization' }
PCRE2Match >> reset [

	isPersistent := false.
	startIndex := nil.
	offsets := nil.
	mark := nil.
	subject := nil.
	decoder := nil.
	input := nil.
	nameTable := nil.
	resultCode := nil
]

{ #category : 'accessing' }
PCRE2Match >> resultCode [
	"Answer the raw PCRE2 result code that produced this match data. Positive values are complete matches; PCRE2 errorPartial identifies partial matches."

	^ resultCode
]

{ #category : 'private' }
PCRE2Match >> resultCode: anInteger [
	"Record the raw PCRE2 result code for this match attempt."

	resultCode := anInteger
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
	"Remember raw subject storage used for this match so callers can query the result later."

	input := nil.
	subject := aByteArray.
	decoder := aDecoder
]

{ #category : 'private' }
PCRE2Match >> unsetOffset [
	"Answer PCRE2_UNSET for the current platform's PCRE2_SIZE width."

	^ (1 bitShift: 8 * ExternalAddress wordSize) - 1
]
