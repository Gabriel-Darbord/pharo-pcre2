"
A read-only encoded subject view. Positions and size count PCRE2 code units. Unicode reads advance over a complete code point, while raw unit reads also permit positions reached through backslash C.
"
Class {
	#name : 'PCRE2SubjectText',
	#superclass : 'SequenceableCollection',
	#instVars : [
		'bytes',
		'width',
		'utf'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

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
	utf := unicode
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
PCRE2SubjectText >> isBoundary: offset [

	(offset = 0 or: [ offset = self size ]) ifTrue: [ ^ true ].
	utf ifFalse: [ ^ true ].
	width = 8 ifTrue: [ ^ ((self codeUnitAtOffset: offset) bitAnd: 192) ~= 128 ].
	width = 16 ifTrue: [ ^ ((self codeUnitAtOffset: offset) between: 16rDC00 and: 16rDFFF) not ].
	^ true
]

{ #category : 'accessing' }
PCRE2SubjectText >> lookbehindStartsMinimum: minimum maximum: maximum at: target [

	| result offset distance |
	result := OrderedCollection new.
	offset := target.
	distance := 0.
	[ offset >= 0 and: [ distance <= maximum ] ] whileTrue: [
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
PCRE2SubjectText >> previousOffsetFrom: offset [

	| previous |
	offset <= 0 ifTrue: [ ^ -1 ].
	previous := offset - 1.
	utf ifFalse: [ ^ previous ].
	width = 8 ifTrue: [
		[ previous > 0 and: [ ((self codeUnitAtOffset: previous) bitAnd: 192) = 128 ] ] whileTrue: [ previous := previous - 1 ] ].
	(width = 16 and: [ previous > 0 and: [ (self codeUnitAtOffset: previous) between: 16rDC00 and: 16rDFFF ] ]) ifTrue: [
		((self codeUnitAtOffset: previous - 1) between: 16rD800 and: 16rDBFF) ifTrue: [ previous := previous - 1 ] ].
	^ previous
]

{ #category : 'accessing' }
PCRE2SubjectText >> size [

	^ bytes size // (width // 8)
]

{ #category : 'accessing' }
PCRE2SubjectText >> species [

	^ Array
]
