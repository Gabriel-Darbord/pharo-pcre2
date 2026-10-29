"
Reads raw code units without interpreting UTF surrogate pairs or UTF-8 sequences. The parser and matcher use this only when PCRE2_UTF is disabled.
"
Class {
	#name : 'PCRE2CodeUnitText',
	#superclass : 'Object',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'decoding' }
PCRE2CodeUnitText class >> from: bytes width: width [

	width = 8 ifTrue: [ ^ bytes asString ].
	^ String streamContents: [ :stream |
			  0 to: bytes size - (width // 8) by: width // 8 do: [ :offset |
					  stream nextPut: (Character value: (width = 16
								    ifTrue: [ bytes uint16AtOffset: offset ]
								    ifFalse: [ bytes uint32AtOffset: offset ])) ] ]
]

{ #category : 'decoding' }
PCRE2CodeUnitText class >> validateUTF: bytes width: width [

	| offset first second |
	width = 8 ifTrue: [ ^ self ].
	offset := 0.
	[ offset < bytes size ] whileTrue: [
			first := width = 16
				         ifTrue: [ bytes uint16AtOffset: offset ]
				         ifFalse: [ bytes uint32AtOffset: offset ].
			offset := offset + (width // 8).
			width = 32
				ifTrue: [
				(first > 16r10FFFF or: [ first between: 16rD800 and: 16rDFFF ]) ifTrue: [ PCRE2MatchError signal: 'invalid UTF subject' ] ]
				ifFalse: [
						(first between: 16rD800 and: 16rDBFF)
							ifTrue: [
									offset >= bytes size ifTrue: [ PCRE2MatchError signal: 'invalid UTF subject' ].
									second := bytes uint16AtOffset: offset.
									(second between: 16rDC00 and: 16rDFFF) ifFalse: [ PCRE2MatchError signal: 'invalid UTF subject' ].
									offset := offset + 2 ]
							ifFalse: [ (first between: 16rDC00 and: 16rDFFF) ifTrue: [ PCRE2MatchError signal: 'invalid UTF subject' ] ] ] ]
]
