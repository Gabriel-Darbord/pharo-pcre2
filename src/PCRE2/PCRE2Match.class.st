"
Standalone match results with numbered and named captures, encoded offsets, and remembered subject input. A backend owns the result representation. FFI results can be materialized before image shutdown; Pharo results already live entirely in the image.
"
Class {
	#name : 'PCRE2Match',
	#superclass : 'Object',
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
		'resultCode',
		'matchDataSize',
		'heapframesSize',
		'backend'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2Match class >> isAbstract [

	^ self == PCRE2Match
]

{ #category : 'external resource management' }
PCRE2Match >> autoRelease [

	backend autoRelease
]

{ #category : 'accessing' }
PCRE2Match >> backend [

	^ backend
]

{ #category : 'accessing' }
PCRE2Match >> backend: anImplementation [

	backend ifNotNil: [ PCRE2Error signal: 'Match results cannot change backend' ].
	backend := anImplementation
]

{ #category : 'persistence' }
PCRE2Match >> cacheForSnapshot [

	self
		count;
		matchDataSize;
		heapframesSize;
		startIndex;
		mark;
		offsets
]

{ #category : 'private' }
PCRE2Match >> captureIndexesNamed: groupName [
	"Answer all capture group numbers associated with groupName. Duplicate names are preserved in capture order."

	| indexes |
	indexes := OrderedCollection new.
	self namedGroups keysAndValuesDo: [ :captureIndex :name | name = groupName ifTrue: [ indexes add: captureIndex ] ].
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

{ #category : 'enumerating' }
PCRE2Match >> endOffsetAt: pairIndex [

	^ (self offsetsAt: pairIndex) second
]

{ #category : 'private' }
PCRE2Match >> ensureSubjectAvailable [

	(input isNil and: [ subject isNil ]) ifTrue: [
		self error: 'This match does not remember a subject; use readMatch: or readMatches: with an explicit subject' ]
]

{ #category : 'library path' }
PCRE2Match >> ffiLibraryName [

	^ backend ffiLibraryName
]

{ #category : 'external resource management' }
PCRE2Match >> finalize [

	backend finalize
]

{ #category : 'external resource management' }
PCRE2Match >> free [

	backend free
]

{ #category : 'private' }
PCRE2Match >> getCount [

	^ backend getCount
]

{ #category : 'private' }
PCRE2Match >> getHandle [

	^ backend getHandle
]

{ #category : 'private' }
PCRE2Match >> getHeapframesSize [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getMark [

	^ backend getMark
]

{ #category : 'private' }
PCRE2Match >> getMarkPointer [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getMatchDataSize [

	^ backend getMatchDataSize
]

{ #category : 'private' }
PCRE2Match >> getOffsets [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2Match >> getStartIndex [

	^ backend getStartIndex
]

{ #category : 'group access' }
PCRE2Match >> groupAt: groupNumber [
	"Answer the matched text for groupNumber, where 0 is the whole match and 1 is the first capture. Answer nil for an optional capture group that did not participate in the match."

	| pair |
	(groupNumber isInteger and: [ groupNumber >= 0 ]) ifFalse: [ self error: 'Group number must be a non-negative integer' ].
	groupNumber >= self count ifTrue: [ ^ nil ].

	self ensureSubjectAvailable.
	pair := self offsetsAt: groupNumber + 1.
	pair first = PCRE2 unsetOffset ifTrue: [ ^ nil ].
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
		(name notNil and: [ (groups includesKey: name) not ]) ifTrue: [ groups at: name put: (self groupNamed: name) ] ].
	^ groups
]

{ #category : 'group access' }
PCRE2Match >> groupsNamed: groupName [
	"Answer all matched texts for groupName in capture order. Duplicate names are preserved; optional captures that did not participate answer nil in their position."

	^ (self captureIndexesNamed: groupName) collect: [ :captureIndex | self groupAt: captureIndex ]
]

{ #category : 'accessing' }
PCRE2Match >> heapframesSize [

	heapframesSize ifNotNil: [ ^ heapframesSize ].
	backend isNull ifTrue: [ ^ nil ].
	^ heapframesSize := backend heapframesSize
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

{ #category : 'private' }
PCRE2Match >> invalidateResult [

	isPersistent := false.
	startIndex := nil.
	offsets := nil.
	mark := nil.
	resultCode := nil.
	heapframesSize := nil
]

{ #category : 'testing' }
PCRE2Match >> isComplete [
	"Answer whether PCRE2 returned a complete match result."

	^ resultCode notNil and: [ resultCode > 0 ]
]

{ #category : 'testing' }
PCRE2Match >> isNull [

	^ backend isNull
]

{ #category : 'testing' }
PCRE2Match >> isPartial [
	"Answer whether PCRE2 returned PCRE2_ERROR_PARTIAL for this result."

	^ resultCode = PCRE2 errorPartial
]

{ #category : 'persistence' }
PCRE2Match >> isPersistent [

	^ isPersistent or: [ backend isNull ]
]

{ #category : 'enumerating' }
PCRE2Match >> lastMatchIndex [

	^ self endOffsetAt: 1
]

{ #category : 'accessing' }
PCRE2Match >> mark [

	mark ifNotNil: [ ^ mark ].
	backend isNull ifTrue: [ ^ nil ].
	^ mark := self getMark ifEmpty: [ nil ]
]

{ #category : 'diagnostics' }
PCRE2Match >> matchDataSize [
	"Answer the native memory used by this PCRE2 match-data block, in bytes. The value is cached so persistent matches can still report it after freeing the native handle."

	^ matchDataSize ifNil: [ matchDataSize := self getMatchDataSize ]
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
	"Return raw PCRE2 code-unit offset pairs for the match and captures; starts are zero-based inclusive entries and ends are zero-based exclusive entries. Do not modify the returned array."

	| copy pair |
	"Copy external data locally if needed, preserving PCRE2's zero-based code-unit offset convention."
	offsets isArray ifTrue: [ ^ offsets ].
	copy := Array new: 2 * self count.
	1 to: self count do: [ :pairIndex |
			pair := self offsetsAt: pairIndex.
			copy at: 2 * pairIndex - 1 put: pair first.
			copy at: 2 * pairIndex put: pair second ].
	^ offsets := copy
]

{ #category : 'enumerating' }
PCRE2Match >> offsetsAt: pairIndex [

	offsets ifNotNil: [
			^ {
				  (offsets at: 2 * pairIndex - 1).
				  (offsets at: 2 * pairIndex) } ].
	^ backend offsetsAt: pairIndex
]

{ #category : 'enumerating' }
PCRE2Match >> offsetsDo: aBlock [

	1 to: self count do: [ :index |
			| pair |
			pair := self offsetsAt: index.
			aBlock value: pair first + 1 value: pair second ]
]

{ #category : 'accessing' }
PCRE2Match >> ovectorCount [
	"Return the number of PCRE2 code-unit offset pairs available in this match data block."

	^ self getCount
]

{ #category : 'persistence' }
PCRE2Match >> prepareForShutdown [

	self cacheForSnapshot.
	backend finalize.
	isPersistent := true
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
	^ decoder ifNil: [ bytes ] ifNotNil: [ bytes ifNotNil: [ decoder decodeBytes: bytes ] ]
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
			self offsetsDo: [ :start :end | matches at: (index := index + 1) put: (input readFrom: start to: end) ].
			^ matches ].
	^ decoder ifNil: [ self readMatches: subject ] ifNotNil: [ self readMatches: subject decodeWith: decoder ]
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatches: subject [
	"Returns the matching subcollections of a pattern and its groups applied to subject"

	| matches index |
	matches := Array new: self count.
	index := 0.
	self offsetsDo: [ :start :end | matches at: (index := index + 1) put: (subject copyFrom: start to: end) ].
	^ matches
]

{ #category : 'match enumeration' }
PCRE2Match >> readMatches: subject decodeWith: decoder [
	"Returns the decoded matching subcollections of a pattern and its groups applied to subject"

	| matches index |
	matches := Array new: self count.
	index := 0.
	self offsetsDo: [ :start :end | matches at: (index := index + 1) put: (decoder decodeBytes: (subject copyFrom: start to: end)) ].
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
	resultCode := nil.
	matchDataSize := nil.
	heapframesSize := nil
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

{ #category : 'enumerating' }
PCRE2Match >> startOffsetAt: pairIndex [

	^ (self offsetsAt: pairIndex) first
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
