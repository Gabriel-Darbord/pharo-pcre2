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
	"Update myself to become a persistent version."

	self count.
	offsets isArray ifFalse: [ "copy external data into local memory"
		self offsets ].
	"TODO named groups"
	isPersistent := true.
	self finalize "free and make handle NULL"

	"Must use #becomeForward: to update all references.
	While the match data should generally not be used outside of this API,
	tools such as debuggers still have references to it, so this is essential."

	"self becomeForward: self asPersistentMatch"
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
	"After a call of match() that was passed the match block that is this function's argument, this function returns a pointer to the last (*MARK), (*PRUNE), or (*THEN) name that was encountered during the matching process.
	The name is zero-terminated, and is within the compiled pattern.
	The length of the name is in the preceding code unit.
	If no name is available, NULL is returned."

	"PCRE2_SPTR pcre2_get_mark(pcre2_match_data *match_data)"

	self ffiCall: #(char *pcre2_get_mark_8(self))
]

{ #category : 'private' }
PCRE2Match >> getOffsetsVector [

	self ffiCall: #(size_t *pcre2_get_ovector_pointer_8(self))
]

{ #category : 'private' }
PCRE2Match >> getStartIndex [
	"PCRE2_SIZE pcre2_get_startchar(pcre2_match_data *match_data)"

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
			  offsets ifNil: [ offsets := self getOffsetsVector ].
			  offsets uint64AtOffset: 8 "TODO handle size_t" ]
]

{ #category : 'accessing' }
PCRE2Match >> mark [

	^ mark ifNil: [ mark := self getMark ]
]

{ #category : 'enumerating' }
PCRE2Match >> offsets [
	"Returns a copy of the array containing offset pairs for the match and captured substrings.
	The start offsets are at odd indexes, and the corresponding end offsets are at the following even indexes.
	The first pair identifies the part of the subject string that was matched by the entire pattern.
	Subsequent pairs identify the captured substrings."

	| copy index |
	isPersistent ifTrue: [ ^ offsets clone ].
	copy := Array new: 2 * self count.
	index := 0.
	self offsetsDo: [ :start :end |
		copy at: index + 1 put: start.
		copy at: (index := index + 2) put: end ].
	^ (offsets := copy) clone
]

{ #category : 'accessing' }
PCRE2Match >> offsetsAt: pairIndex [

	| index wordSize |
	index := pairIndex - 1 * 2.
	isPersistent ifTrue: [
		^ {
			  (offsets at: index + 1).
			  (offsets at: index + 2) } ].

	offsets ifNil: [ offsets := self getOffsetsVector ].
	wordSize := ExternalAddress wordSize.
	^ wordSize == 8
		  ifTrue: [
			  {
				  (offsets uint64AtOffset: index * wordSize).
				  (offsets uint64AtOffset: index + 1 * wordSize) } ]
		  ifFalse: [ "assuming wordSize = 4"
			  {
				  (offsets uint32AtOffset: index * wordSize).
				  (offsets uint32AtOffset: index + 1 * wordSize) } ]
]

{ #category : 'enumerating' }
PCRE2Match >> offsetsDo: aBlock [
	"Iterate over the offset pairs resulting from a match operation"

	isPersistent ifTrue: [
		1 to: count by: 2 do: [ :i |
		aBlock value: (offsets at: i) value: (offsets at: i + 1) ].
		^ self ].

	offsets ifNil: [ offsets := self getOffsetsVector ]. "table containing pairs of 0-based indexes"

	"How to make sure we read with the correct size for the `size_t` type (can obtain using `FFIArchitecture forCurrentArchitecture sizeTTypeSize`).
	We also need the primitive of uint64AtOffset: (or equivalent depending on size), and platformSizeTAt: fails."

	"collect all matches, the first pair is what the full pattern matched, subsequent pairs are group matches, one for each"
	1 to: self count do: [ :i | "first index is start of match, second is one after end"
		| start end |
		"let n = sizeof(size_t), start follows the progression n(2i-2), end follows n(2i-1)
		for example with n = 8, start = 0, 16, 32, 48... and end = 8, 24, 40, 56...
		considering sizeof(size_t) = 8 bytes for now..."
		start := (offsets uint64AtOffset: i - 1 * 16) + 1. "from 0 to 1-based"
		end := offsets uint64AtOffset: i * 16 - 8. "no offset because we also need to decrement"
		aBlock value: start value: end ]
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatch: subject [
	"Return the first subset of the subject that matched"

	self offsetsDo: [ :start :end |
		^ subject copyFrom: start to: end ].
	^ nil
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
