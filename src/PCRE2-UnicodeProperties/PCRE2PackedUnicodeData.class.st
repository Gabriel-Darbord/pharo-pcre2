"
Unicode data carried as one base64 literal of gzipped LEB128 varints, as `scripts/generate-unicode-data.py` writes it from a pinned PCRE2 checkout. Tables of code points are stored as gaps, which makes the literal a third of the size of the same data as gzipped JSON.

A subclass answers its literal in `encoded` and reads its sections in `decode:`, in the order the script writes them.

Unicode data uses docs/Unicode-LICENSE.txt; the PCRE2 property catalog uses docs/PCRE2-LICENCE.md.
"
Class {
	#name : 'PCRE2PackedUnicodeData',
	#superclass : 'Object',
	#classInstVars : [
		'data'
	],
	#category : 'PCRE2-UnicodeProperties',
	#package : 'PCRE2-UnicodeProperties'
}

{ #category : 'accessing' }
PCRE2PackedUnicodeData class >> data [
	"The unpacked sections, read once and kept for the session."

	^ data ifNil: [ data := self decode: (GZipReadStream on: self encoded base64Decoded readStream) contents asByteArray ]
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> decode: bytes [
	"Read the sections scripts/generate-unicode-data.py packs for this class, in the order it writes them."

	^ self subclassResponsibility
]

{ #category : 'generated data' }
PCRE2PackedUnicodeData class >> encoded [
	"The packed sections, gzipped, in base64."

	^ self subclassResponsibility
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> readCodeTableFrom: stream [
	"Codes in ascending order as gaps, each followed by its value."

	| table code |
	table := Dictionary new.
	code := 0.
	(self readVarintFrom: stream) timesRepeat: [
			code := code + (self readVarintFrom: stream).
			table at: code put: (self readVarintFrom: stream) ].
	^ table
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> readRangesFrom: stream [
	"Inclusive pairs, each stored as the gap since the last end and its own length."

	| count ranges previous start |
	count := self readVarintFrom: stream.
	ranges := Array new: count * 2.
	previous := 0.
	1 to: count do: [ :index |
			start := previous + (self readVarintFrom: stream).
			previous := start + (self readVarintFrom: stream).
			ranges
				at: index * 2 - 1 put: start;
				at: index * 2 put: previous ].
	^ ranges
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> readTextFrom: stream [
	"A length-prefixed UTF-8 block of lines."

	| bytes |
	bytes := stream next: (self readVarintFrom: stream).
	^ (ZnCharacterEncoder utf8 decodeBytes: bytes) substrings: (String with: Character lf)
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> readTriplesFrom: stream [
	"Runs of first code, last code and a value, each run stored as the gap since the last end, its length and its value."

	| count triples previous start |
	count := self readVarintFrom: stream.
	triples := Array new: count * 3.
	previous := 0.
	1 to: count do: [ :index |
			start := previous + (self readVarintFrom: stream).
			previous := start + (self readVarintFrom: stream).
			triples
				at: index * 3 - 2 put: start;
				at: index * 3 - 1 put: previous;
				at: index * 3 put: (self readVarintFrom: stream) ].
	^ triples
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> readVarintFrom: stream [
	"LEB128: seven bits at a time, low group first, high bit set while more follow."

	| value shift byte |
	value := 0.
	shift := 0.
	[
		byte := stream next.
		value := value + ((byte bitAnd: 16r7F) bitShift: shift).
		shift := shift + 7.
		byte >= 16r80 ] whileTrue.
	^ value
]

{ #category : 'class initialization' }
PCRE2PackedUnicodeData class >> reset [

	data := nil
]

{ #category : 'decoding' }
PCRE2PackedUnicodeData class >> skipRangesFrom: stream [
	"Step over one range list without building it."

	(self readVarintFrom: stream) * 2 timesRepeat: [ self readVarintFrom: stream ]
]

{ #category : 'accessing' }
PCRE2PackedUnicodeData class >> version [
	"The Unicode version the data was generated from."

	^ self data at: 'version'
]
