"
A read-only encoded subject view whose positions and size count PCRE2 code units; Unicode reads advance over a whole code point, raw unit reads also allow positions reached through \C. It shows a window of its storage: `limit` ends the subject for matching and `floor` is the earliest offset a lookbehind may reach, which PCRE2_MATCH_INVALID_UTF narrows to one fragment of valid UTF at a time.
"
Class {
	#name : 'PCRE2SubjectText',
	#superclass : 'SequenceableCollection',
	#instVars : [
		'bytes',
		'width',
		'utf',
		'floor',
		'limit'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'enumerating' }
PCRE2SubjectText >> anyCodeSatisfy: aBlock [
	"Whether the code of any character in this window satisfies the block. Characters are read whole from the floor up, so a subject that is not valid UTF is never read past the window's edges."

	| offset |
	offset := floor.
	[ offset < limit ] whileTrue: [
			(aBlock value: (self codePointAtOffset: offset)) ifTrue: [ ^ true ].
			offset := self nextOffsetFrom: offset ].
	^ false
]

{ #category : 'enumerating' }
PCRE2SubjectText >> anySatisfy: aBlock [

	^ self anyCodeSatisfy: [ :code | aBlock value: (PCRE2CodeUnit fromInteger: code) ]
]

{ #category : 'accessing' }
PCRE2SubjectText >> at: index [

	^ PCRE2CodeUnit fromInteger: (self codePointAtOffset: index - 1)
]

{ #category : 'accessing' }
PCRE2SubjectText >> at: index put: value [

	self error: 'Encoded subject views are read-only'
]

{ #category : 'accessing' }
PCRE2SubjectText >> bytes: storage width: codeUnitWidth utf: unicode [

	bytes := storage.
	width := codeUnitWidth.
	utf := unicode.
	floor := 0.
	limit := storage size // (codeUnitWidth // 8)
]

{ #category : 'accessing' }
PCRE2SubjectText >> characterStartFrom: offset upTo: end [
	"The first offset from this one at which a character can begin, giving up at end."

	| result |
	result := offset.
	[ result < end and: [ (self startsCharacterAt: result) not ] ] whileTrue: [ result := result + 1 ].
	^ result
]

{ #category : 'accessing' }
PCRE2SubjectText >> charactersFrom: start to: end [

	| result offset step |
	result := OrderedCollection new.
	offset := start.
	[ offset < end ] whileTrue: [
			step := self pointWidthAtOffset: offset.
			step > (end - offset)
				ifTrue: [
						result add: (PCRE2CodeUnit fromInteger: (self codeUnitAtOffset: offset)).
						offset := offset + 1 ]
				ifFalse: [
						result add: (self at: offset + 1).
						offset := offset + step ] ].
	^ result asArray
]

{ #category : 'accessing' }
PCRE2SubjectText >> codePointAtOffset: offset [

	| first count code |
	first := self codeUnitAtOffset: offset.
	count := self pointWidthAtOffset: offset.
	count = 1 ifTrue: [ ^ first ].
	offset + count > self size ifTrue: [ PCRE2MatchError signal: 'invalid UTF subject' ].
	width = 16 ifTrue: [ ^ 16r10000 + (first - 16rD800 bitShift: 10) + (self codeUnitAtOffset: offset + 1) - 16rDC00 ].
	code := first bitAnd: (count = 2
			         ifTrue: [ 31 ]
			         ifFalse: [
					         count = 3
						         ifTrue: [ 15 ]
						         ifFalse: [ 7 ] ]).
	1 to: count - 1 do: [ :index | code := (code bitShift: 6) + ((self codeUnitAtOffset: offset + index) bitAnd: 63) ].
	^ code
]

{ #category : 'accessing' }
PCRE2SubjectText >> codeUnitAtOffset: offset [

	width = 8 ifTrue: [ ^ (bytes at: offset + 1) asInteger ].
	width = 16 ifTrue: [ ^ bytes uint16AtOffset: offset * 2 ].
	^ bytes uint32AtOffset: offset * 4
]

{ #category : 'accessing' }
PCRE2SubjectText >> codeUnitCount [
	"The size of the whole subject, whatever window this view shows of it."

	^ bytes size // (width // 8)
]

{ #category : 'accessing' }
PCRE2SubjectText >> floor [

	^ floor
]

{ #category : 'accessing' }
PCRE2SubjectText >> floor: start limit: end [

	floor := start.
	limit := end
]

{ #category : 'accessing' }
PCRE2SubjectText >> fragmentFrom: start to: end [
	"A view of the same subject narrowed to one fragment of valid UTF: matching stops at end, and nothing before start can be read behind a match."

	^ (self class new bytes: bytes width: width utf: utf) floor: start limit: end
]

{ #category : 'accessing' }
PCRE2SubjectText >> invalidOffsetFrom: offset [
	"Where the first invalid UTF sequence at or after this offset begins, or nil when the rest of the subject is valid."

	^ (PCRE2CodeUnitText utfErrorIn: bytes width: width from: offset) ifNotNil: [ :error | error second ]
]

{ #category : 'accessing' }
PCRE2SubjectText >> isBoundary: offset [

	(offset = 0 or: [ offset = self size ]) ifTrue: [ ^ true ].
	^ self startsCharacterAt: offset
]

{ #category : 'accessing' }
PCRE2SubjectText >> isByteWide [
	"Whether one code unit is one byte and the window is the whole subject, which is what a matcher reading the storage directly needs."

	^ width = 8 and: [ floor = 0 and: [ limit = bytes size ] ]
]

{ #category : 'accessing' }
PCRE2SubjectText >> lookbehindStartsMinimum: minimum maximum: maximum at: target [

	| result offset distance |
	result := OrderedCollection new.
	offset := target.
	distance := 0.
	[ offset >= floor and: [ distance <= maximum ] ] whileTrue: [
			distance >= minimum ifTrue: [ result add: offset ].
			offset := self previousOffsetFrom: offset.
			distance := distance + 1 ].
	^ result reversed
]

{ #category : 'accessing' }
PCRE2SubjectText >> nextOffsetFrom: offset [

	offset >= self size ifTrue: [ ^ self size + 1 ].
	^ offset + (self pointWidthAtOffset: offset)
]

{ #category : 'accessing' }
PCRE2SubjectText >> pointWidthAtOffset: offset [

	| first |
	utf ifFalse: [ ^ 1 ].
	width = 32 ifTrue: [ ^ 1 ].
	first := self codeUnitAtOffset: offset.
	width = 16 ifTrue: [
			^ ((first between: 16rD800 and: 16rDBFF) and: [
				   offset + 1 < self size and: [ (self codeUnitAtOffset: offset + 1) between: 16rDC00 and: 16rDFFF ] ])
				  ifTrue: [ 2 ]
				  ifFalse: [ 1 ] ].
	first < 192 ifTrue: [ ^ 1 ].
	first < 224 ifTrue: [ ^ 2 ].
	first < 240 ifTrue: [ ^ 3 ].
	^ 4
]

{ #category : 'accessing' }
PCRE2SubjectText >> prefixTo: end [

	^ self class new bytes: (bytes copyFrom: 1 to: end * (width // 8)) width: width utf: utf
]

{ #category : 'accessing' }
PCRE2SubjectText >> previousOffsetFrom: offset [

	| previous |
	offset <= floor ifTrue: [ ^ -1 ].
	previous := offset - 1.
	utf ifFalse: [ ^ previous ].
	width = 8 ifTrue: [
		[ previous > floor and: [ ((self codeUnitAtOffset: previous) bitAnd: 192) = 128 ] ] whileTrue: [ previous := previous - 1 ] ].
	(width = 16 and: [ previous > floor and: [ (self codeUnitAtOffset: previous) between: 16rDC00 and: 16rDFFF ] ]) ifTrue: [
		((self codeUnitAtOffset: previous - 1) between: 16rD800 and: 16rDBFF) ifTrue: [ previous := previous - 1 ] ].
	^ previous
]

{ #category : 'accessing' }
PCRE2SubjectText >> size [

	^ limit
]

{ #category : 'accessing' }
PCRE2SubjectText >> species [

	^ Array
]

{ #category : 'accessing' }
PCRE2SubjectText >> startsCharacterAt: offset [
	"Whether a character can begin at this offset. In UTF-8 and UTF-16 a continuation unit cannot."

	utf ifFalse: [ ^ true ].
	width = 8 ifTrue: [ ^ ((self codeUnitAtOffset: offset) bitAnd: 192) ~= 128 ].
	width = 16 ifTrue: [ ^ ((self codeUnitAtOffset: offset) between: 16rDC00 and: 16rDFFF) not ].
	^ true
]

{ #category : 'accessing' }
PCRE2SubjectText >> storage [
	"The raw code units. Only a matcher that knows the width should read them."

	^ bytes
]
