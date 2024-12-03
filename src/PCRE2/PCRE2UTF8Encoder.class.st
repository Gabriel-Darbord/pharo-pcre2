"
I can encode a string to UTF-8 and translate a range to the equivalent encoded range.
This is needed to calculate the offset of a range over a Pharo string, which has a fixed-length encoding, to a UTF-8 string, which has a variable-length encoding.
For example, the string `'où'` is encoded as `#[111 195 185]`, so the range [2, 2] is translated to [2, 3].

During an FFI call, string arguments are always converted to UTF-8 byte arrays with `String>>#utf8Encoded`.
To work around this, `PCRE2UTF8Encoder` must be used to do the conversion for patterns and subjects before the call.
The API handles this conversion, so there should be no need to use me unless you have some specific needs.
"
Class {
	#name : 'PCRE2UTF8Encoder',
	#superclass : 'ZnUTF8Encoder',
	#instVars : [
		'utfEnd',
		'utfStart',
		'end',
		'start',
		'index'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2UTF8Encoder class >> from: start to: end [

	^ self new
		  start: start;
		  end: end
]

{ #category : 'convenience' }
PCRE2UTF8Encoder >> encodeString: string [
	"Encode string and return the resulting byte array"

	index := utfStart := utfEnd := 0. "correct values if empty"
	string ifEmpty: [ ^ ByteArray new ].
	utfStart := 1.
	^ ByteArray new: (string size max: 100) streamContents: [ :stream |
		  string isByteString
			  ifTrue: [ self nextPutAllByteString: string toStream: stream ]
			  ifFalse: [
				  1 to: string size do: [ :i |
					  self
						  nextPutCodePoint: (string at: i) asInteger
						  toStream: stream ] ] ]
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> end [

	^ end
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> end: anInteger [

	end := anInteger
]

{ #category : 'initialization' }
PCRE2UTF8Encoder >> initialize [

	start := end := utfStart := utfEnd := 0
]

{ #category : 'private' }
PCRE2UTF8Encoder >> next: count countASCII: string startingAt: offset [
	"Write count bytes from string starting at offset to stream,
	assuming all characters are in the ASCII set and need no translation"

	| nextIndex |
	"compute the utf offsets at once instead of iterating"
	nextIndex := index + count.
	(index := index + 1) < start ifTrue: [
		utfStart := utfStart + (nextIndex < start
			             ifTrue: [ count ]
			             ifFalse: [ start - index ]) ].
	index <= end ifTrue: [
		utfEnd := utfEnd + (nextIndex <= end
			           ifTrue: [ count ]
			           ifFalse: [ end - index + 1 ]) ].
	index := nextIndex
]

{ #category : 'private' }
PCRE2UTF8Encoder >> next: count putAllASCII: string startingAt: offset toStream: stream [
	"Write count bytes from string starting at offset to stream,
	assuming all characters are in the ASCII set and need no translation"

	| nextIndex |
	"compute the utf offsets at once instead of iterating"
	nextIndex := index + count.
	(index := index + 1) < start ifTrue: [
		utfStart := utfStart + (nextIndex < start
			             ifTrue: [ count ]
			             ifFalse: [ start - index ]) ].
	index <= end ifTrue: [
		utfEnd := utfEnd + (nextIndex <= end
			           ifTrue: [ count ]
			           ifFalse: [ end - index + 1 ]) ].
	index := nextIndex.

	offset to: offset + count - 1 do: [ :i |
		stream nextPut: (string byteAt: i) ]
]

{ #category : 'private' }
PCRE2UTF8Encoder >> nextCountByteString: string [
	"A faster version when string is a ByteString"

	| count lastIndex nextIndex |
	count := string size.
	lastIndex := 1.
	nextIndex := ByteString findFirstInString: string inSet: ByteASCIISet startingAt: 1.
	nextIndex = 0 ifTrue: [
		^ self next: count countASCII: string startingAt: 1 ].
	[	| encoding |
		nextIndex > lastIndex ifTrue: [
			self next: nextIndex - lastIndex countASCII: string startingAt: lastIndex ].
		encoding := ByteUTF8Encoding at: (string byteAt: nextIndex) + 1.
		(index := index + 1) < start ifTrue: [ utfStart := utfStart + encoding size ].
		index <= end ifTrue: [ utfEnd := utfEnd + encoding size ].
		lastIndex := nextIndex + 1.
		nextIndex := ByteString findFirstInString: string inSet: ByteASCIISet startingAt: lastIndex.
		nextIndex = 0 ] whileFalse.
	lastIndex < count ifTrue: [
		self next: 1 + count - lastIndex countASCII: string startingAt: lastIndex ]
]

{ #category : 'encoding - decoding' }
PCRE2UTF8Encoder >> nextCountCodePoint: codePoint [
	"Write the encoding for Integer code point to stream and keep track of its size."

	index := index + 1.
	codePoint < 128 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 1 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 1 ].
		^ self ].
	codePoint < 2048 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 2 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 2 ].
		^ self ].
	(self isSurrogateCodePoint: codePoint) ifTrue: [ ^ self errorOutsideRange ].
	codePoint < 65536 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 3 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 3 ].
		^ self ].
	codePoint <= self maximumUTFCode ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 4 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 4 ].
		^ self ].
	^ self errorOutsideRange
]

{ #category : 'private' }
PCRE2UTF8Encoder >> nextPutAllByteString: string toStream: stream [
	"A faster version when string is a ByteString"

	| count lastIndex nextIndex |
	count := string size.
	lastIndex := 1.
	nextIndex := ByteString findFirstInString: string inSet: ByteASCIISet startingAt: 1.
	nextIndex = 0 ifTrue: [
		^ self next: count putAllASCII: string startingAt: 1 toStream: stream ].
	[	| encoding |
		nextIndex > lastIndex ifTrue: [
			self next: nextIndex - lastIndex putAllASCII: string startingAt: lastIndex toStream: stream ].
		encoding := ByteUTF8Encoding at: (string byteAt: nextIndex) + 1.
		stream nextPutAll: encoding.
		(index := index + 1) < start ifTrue: [ utfStart := utfStart + encoding size ].
		index <= end ifTrue: [ utfEnd := utfEnd + encoding size ].
		lastIndex := nextIndex + 1.
		nextIndex := ByteString findFirstInString: string inSet: ByteASCIISet startingAt: lastIndex.
		nextIndex = 0 ] whileFalse.
	lastIndex < count ifTrue: [
		self next: 1 + count - lastIndex putAllASCII: string startingAt: lastIndex toStream: stream ]
]

{ #category : 'encoding - decoding' }
PCRE2UTF8Encoder >> nextPutCodePoint: codePoint toStream: stream [
	"Write the encoding for Integer code point to stream and keep track of its size."

	index := index + 1.
	codePoint < 128 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 1 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 1 ].
		^ stream nextPut: codePoint ].
	codePoint < 2048 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 2 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 2 ].
		^ stream
			nextPut: (2r11000000 + (codePoint bitShift: -6));
			nextPut: (2r10000000 + (codePoint bitAnd: 2r111111)) ].
	(self isSurrogateCodePoint: codePoint) ifTrue: [ ^ self errorOutsideRange ].
	codePoint < 65536 ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 3 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 3 ].
		^ stream
			nextPut: (2r11100000 + (codePoint bitShift: -12));
			nextPut: (2r10000000 + ((codePoint bitShift: -6) bitAnd: 2r111111));
			nextPut: (2r10000000 + (codePoint bitAnd: 2r111111)) ].
	codePoint <= self maximumUTFCode ifTrue: [
		index < start ifTrue: [ utfStart := utfStart + 4 ].
		index <= end ifTrue: [ utfEnd := utfEnd + 4 ].
		^ stream
			nextPut: (2r11110000 + (codePoint bitShift: -18));
			nextPut: (2r10000000 + ((codePoint bitShift: -12) bitAnd: 2r111111));
			nextPut: (2r10000000 + ((codePoint bitShift: -6) bitAnd: 2r111111));
			nextPut: (2r10000000 + (codePoint bitAnd: 2r111111)) ].
	^ self errorOutsideRange
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> start [

	^ start
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> start: anInteger [

	start := anInteger
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> utfEnd [
	"End value including UTF offset"

	^ utfEnd
]

{ #category : 'accessing' }
PCRE2UTF8Encoder >> utfStart [
	"Start value including UTF offset"

	^ utfStart
]
