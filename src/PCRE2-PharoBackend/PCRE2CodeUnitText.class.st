"
Reads raw code units without interpreting UTF surrogate pairs or UTF-8 sequences. The parser and matcher use this only when PCRE2_UTF is disabled.
"
Class {
	#name : 'PCRE2CodeUnitText',
	#superclass : 'SequenceableCollection',
	#instVars : [
		'units'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'decoding' }
PCRE2CodeUnitText class >> from: bytes width: width [

	| units |
	width = 8 ifTrue: [ ^ bytes asString ].
	units := (0 to: bytes size - (width // 8) by: width // 8) collect: [ :offset |
			         PCRE2CodeUnit fromInteger: (width = 16
					          ifTrue: [ bytes uint16AtOffset: offset ]
					          ifFalse: [ bytes uint32AtOffset: offset ]) ].
	(units allSatisfy: [ :unit | unit isCharacter ]) ifTrue: [ ^ String withAll: units ].
	^ self new units: units asArray
]

{ #category : 'validating' }
PCRE2CodeUnitText class >> utf8ErrorIn: bytes [

	| offset first second additional remaining code |
	offset := 0.
	[ offset < bytes size ] whileTrue: [
			first := (bytes at: offset + 1) asInteger.
			first >= 128 ifTrue: [
					first < 16rC0 ifTrue: [
							^ {
								  -22.
								  offset } ].
					first >= 16rFE ifTrue: [
							^ {
								  -23.
								  offset } ].
					additional := first < 16rE0
						              ifTrue: [ 1 ]
						              ifFalse: [
								              first < 16rF0
									              ifTrue: [ 2 ]
									              ifFalse: [
											              first < 16rF8
												              ifTrue: [ 3 ]
												              ifFalse: [
														              first < 16rFC
															              ifTrue: [ 4 ]
															              ifFalse: [ 5 ] ] ] ].
					remaining := bytes size - offset - 1.
					remaining < additional ifTrue: [
							^ {
								  (-2 - (additional - remaining)).
								  offset } ].
					1 to: additional do: [ :index |
							((bytes at: offset + index + 1) asInteger bitAnd: 16rC0) = 16r80 ifFalse: [
									^ {
										  (-7 - index).
										  offset } ] ].
					second := (bytes at: offset + 2) asInteger.
					code := additional = 1
						        ifTrue: [ first < 16rC2 ifTrue: [ -17 ] ]
						        ifFalse: [
								        additional = 2
									        ifTrue: [
											        (first = 16rE0 and: [ second < 16rA0 ])
												        ifTrue: [ -18 ]
												        ifFalse: [ (first = 16rED and: [ second >= 16rA0 ]) ifTrue: [ -16 ] ] ]
									        ifFalse: [
											        additional = 3
												        ifTrue: [
														        (first = 16rF0 and: [ second < 16r90 ])
															        ifTrue: [ -19 ]
															        ifFalse: [ (first > 16rF4 or: [ first = 16rF4 and: [ second > 16r8F ] ]) ifTrue: [ -15 ] ] ]
												        ifFalse: [
														        additional = 4
															        ifTrue: [
																	        (first = 16rF8 and: [ second < 16r88 ])
																		        ifTrue: [ -20 ]
																		        ifFalse: [ -13 ] ]
															        ifFalse: [
																	        (first = 16rFC and: [ second < 16r84 ])
																		        ifTrue: [ -21 ]
																		        ifFalse: [ -14 ] ] ] ] ].
					code ifNotNil: [
							^ {
								  code.
								  offset } ].
					offset := offset + additional ].
			offset := offset + 1 ].
	^ nil
]

{ #category : 'validating' }
PCRE2CodeUnitText class >> utfErrorIn: bytes width: width [
	"Answer the PCRE2 error code and its code-unit offset, or nil."

	| offset first second size |
	width = 8 ifTrue: [ ^ self utf8ErrorIn: bytes ].
	offset := 0.
	size := bytes size // (width // 8).
	[ offset < size ] whileTrue: [
			first := width = 16
				         ifTrue: [ bytes uint16AtOffset: offset * 2 ]
				         ifFalse: [ bytes uint32AtOffset: offset * 4 ].
			width = 32
				ifTrue: [
						(first between: 16rD800 and: 16rDFFF) ifTrue: [
								^ {
									  -27.
									  offset } ].
						first > 16r10FFFF ifTrue: [
								^ {
									  -28.
									  offset } ] ]
				ifFalse: [
						(first between: 16rD800 and: 16rDBFF)
							ifTrue: [
									offset + 1 >= size ifTrue: [
											^ {
												  -24.
												  offset } ].
									second := bytes uint16AtOffset: offset + 1 * 2.
									(second between: 16rDC00 and: 16rDFFF) ifFalse: [
											^ {
												  -25.
												  offset } ].
									offset := offset + 1 ]
							ifFalse: [
									(first between: 16rDC00 and: 16rDFFF) ifTrue: [
											^ {
												  -26.
												  offset } ] ] ].
			offset := offset + 1 ].
	^ nil
]

{ #category : 'validating' }
PCRE2CodeUnitText class >> validateUTF: bytes width: width [

	(self utfErrorIn: bytes width: width) ifNotNil: [ :error | PCRE2MatchError signal: (PCRE2 translateErrorCode: error first) ]
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> at: index [

	^ units at: index
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> at: index put: value [

	^ units at: index put: value
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> copyFrom: start to: end [

	| result |
	result := units copyFrom: start to: end.
	^ (result allSatisfy: #isCharacter)
		  ifTrue: [ String withAll: result ]
		  ifFalse: [ result ]
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> findString: aString startingAt: start [

	start to: self size - aString size + 1 do: [ :index |
	((1 to: aString size) allSatisfy: [ :i | (self at: index + i - 1) = (aString at: i) ]) ifTrue: [ ^ index ] ].
	^ 0
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> size [

	^ units size
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> species [

	^ Array
]

{ #category : 'accessing' }
PCRE2CodeUnitText >> units: anArray [

	units := anArray
]
