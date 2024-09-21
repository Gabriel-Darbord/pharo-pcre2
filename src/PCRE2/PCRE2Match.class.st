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
		'startIndex'
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
PCRE2Match >> endOffsetAt: pairIndex [
	"Returns the n-th end offset"

	| index wordSize |
	index := 2 * (pairIndex - 1) + 1. "to 0-based"
	offsets isArray ifTrue: [ ^ offsets at: index + 1 ].

	offsets ifNil: [ offsets := self getOffsets ].
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [ ^ offsets uint64AtOffset: 8 * index ].
	wordSize == 4 ifTrue: [ ^ offsets uint32AtOffset: 4 * index ].
	^ offsets platformSizeTAt: wordSize * index + 1
]

{ #category : 'initialize-release' }
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
	"Returns the index of the code unit after the last match"

	^ isPersistent
		  ifTrue: [ offsets at: 2 ]
		  ifFalse: [
			  offsets ifNil: [ offsets := self getOffsets ].
			  offsets uint64AtOffset: 8 "TODO handle size_t" ]
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
	"Returns the n-th offset pair"

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
	"Iterate over the offset pairs resulting from a match operation.
	The first pair is what the full pattern matched, subsequent pairs are the matches of each capture group."

	| wordSize |
	offsets isArray ifTrue: [ "offsets have already been copied to a local array"
		1 to: count by: 2 do: [ :i |
		aBlock value: (offsets at: i) value: (offsets at: i + 1) ].
		^ self ].

	offsets ifNil: [ offsets := self getOffsets ]. "table containing pairs of 0-based indexes"
	wordSize := ExternalAddress wordSize.

	"let n = wordSize = sizeof(size_t), start follows the progression n(2i-2), end follows n(2i-1)
	e.g. with n = 8, start = 0, 16, 32, 48..., end = 8, 24, 40, 56...
	PCRE2 sets the end index as exclusive, but Pharo uses only inclusive, so it is translated
	the start index is incremented to be 1-based, and it stays inclusive
	the end index is incremented (0 to 1-based) but also decremented (to be inclusive)
	e.g. matching 'a' returns the range (offset pair) [0,1) and it is translated as [1,1]"

	wordSize == 8 ifTrue: [ "most cases"
		1 to: self count do: [ :i |
			| start end |
			start := (offsets uint64AtOffset: 16 * (i - 1)) + 1.
			end := offsets uint64AtOffset: 16 * i - 8.
			aBlock value: start value: end ].
		^ self ].

	wordSize == 4 ifTrue: [ "some cases"
		1 to: self count do: [ :i |
			| start end |
			start := (offsets uint32AtOffset: 8 * (i - 1)) + 1.
			end := offsets uint32AtOffset: 8 * i - 4.
			aBlock value: start value: end ].
		^ self ].

	"rare cases, platform-independent but slower"
	1 to: self count do: [ :i | "note that #platformSizeTAt: is 1-based"
		| start end |
		start := (offsets platformSizeTAt: 2 * wordSize * (i - 1) + 1) + 1.
		end := offsets platformSizeTAt: wordSize * (2 * i - 1) + 1.
		aBlock value: start value: end ]
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatch: subject [
	"Returns the matching subcollection of a pattern applied to subject"

	self offsetsDo: [ :start :end | ^ subject copyFrom: start to: end ].
	^ nil
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

{ #category : 'initialization' }
PCRE2Match >> reset [

	isPersistent := false.
	startIndex := nil.
	offsets := nil.
	mark := nil
]

{ #category : 'accessing' }
PCRE2Match >> startIndex [
	"Available after a successful match, a partial match, or one of the invalid UTF errors.
	After a successful or partial match it returns the code unit offset of the character at which the match started.
	For a non-partial match, this can be different from the value of `offsets at: 1` if the pattern contains the \K escape sequence.
	After a partial match, however, this value is always the same as `offsets at: 1` because \K does not affect the result of a partial match."

	^ startIndex ifNil: [ startIndex := self getStartIndex ]
]

{ #category : 'accessing' }
PCRE2Match >> startOffsetAt: pairIndex [
	"Returns the n-th start offset"

	| index wordSize |
	index := 2 * (pairIndex - 1). "to 0-based"
	offsets isArray ifTrue: [ ^ offsets at: index + 1 ].

	offsets ifNil: [ offsets := self getOffsets ].
	wordSize := ExternalAddress wordSize.
	wordSize == 8 ifTrue: [ ^ offsets uint64AtOffset: 8 * index ].
	wordSize == 4 ifTrue: [ ^ offsets uint32AtOffset: 4 * index ].
	^ offsets platformSizeTAt: wordSize * index + 1
]
