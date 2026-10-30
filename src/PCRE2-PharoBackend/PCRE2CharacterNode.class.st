"
One character position, accepted by a predicate. A node that stands for a single literal also keeps that character, which the start optimizations and auto-possessification read.

A character class keeps a table of the codes under 256 it accepts as well, because it is asked once for every character of the subject and almost every character lands there. The table is built by asking the predicate itself, so the two cannot disagree.
"
Class {
	#name : 'PCRE2CharacterNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'predicate',
		'character',
		'table'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'optimization' }
PCRE2CharacterNode class >> tableFor: aPredicate [
	"Which codes under 256 the predicate accepts, worked out once. It is built by asking the predicate itself, so the table and the predicate cannot disagree."

	| table |
	table := ByteArray new: 256.
	0 to: 255 do: [ :code | (aPredicate value: (PCRE2CodeUnit fromInteger: code)) ifTrue: [ table at: code + 1 put: 1 ] ].
	^ table
]

{ #category : 'matching' }
PCRE2CharacterNode >> acceptsCode: code [
	"Whether this item matches the character with this code. A class answers from its table for the codes that fit in one byte, which is where almost every character of a subject lands."

	(table isNil or: [ code > 255 ]) ifTrue: [ ^ predicate value: (PCRE2CodeUnit fromInteger: code) ].
	^ (table at: code + 1) = 1
]

{ #category : 'optimization' }
PCRE2CharacterNode >> canAutoPossess [

	^ true
]

{ #category : 'accessing' }
PCRE2CharacterNode >> character [

	^ character
]

{ #category : 'accessing' }
PCRE2CharacterNode >> character: aCharacter [

	character := aCharacter
]

{ #category : 'matching' }
PCRE2CharacterNode >> countIn: anEngine from: offset limit: maximum [
	"How many characters in a row from this offset are accepted, at most maximum of them, where the run stopped, and the last offset read. The character is read before it is judged, so the one that ends the run was read too."

	| subject size position count read |
	subject := anEngine subject.
	size := subject size.
	position := offset.
	count := 0.
	read := nil.
	[ (maximum isNil or: [ count < maximum ]) and: [ position < size ] ] whileTrue: [
			read := position.
			(self acceptsCode: (subject codePointAtOffset: position)) ifFalse: [
					^ {
						  count.
						  position.
						  read } ].
			position := subject nextOffsetFrom: position.
			count := count + 1 ].
	^ {
		  count.
		  position.
		  read }
]

{ #category : 'matching' }
PCRE2CharacterNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	engine noteInspectionAt: state position.
	(self acceptsCode: (engine subject codePointAtOffset: state position)) ifFalse: [ ^ nil ].
	state position: (engine subject nextOffsetFrom: state position).
	^ state
]

{ #category : 'optimization' }
PCRE2CharacterNode >> firstLiteral [

	^ character
]

{ #category : 'testing' }
PCRE2CharacterNode >> isSingleCharacter [

	^ true
]

{ #category : 'optimization' }
PCRE2CharacterNode >> literalCharacter [

	^ character
]

{ #category : 'accessing' }
PCRE2CharacterNode >> maximumLength [

	^ 1
]

{ #category : 'accessing' }
PCRE2CharacterNode >> minimumLength [

	^ 1
]

{ #category : 'accessing' }
PCRE2CharacterNode >> predicate [

	^ predicate
]

{ #category : 'accessing' }
PCRE2CharacterNode >> predicate: aBlock [

	predicate := aBlock
]

{ #category : 'optimization' }
PCRE2CharacterNode >> requiredNode [

	^ self
]

{ #category : 'optimization' }
PCRE2CharacterNode >> startPredicate [

	^ predicate
]

{ #category : 'optimization' }
PCRE2CharacterNode >> tabulate [
	"Work out once which codes under 256 this item accepts, so that matching reads a byte instead of running the predicate. The predicate itself is wrapped around the table, so every other reader of it gains too. Worth it for a class, not for a single literal, where a comparison is cheaper than a table."

	| tested |
	tested := predicate.
	table := self class tableFor: tested.
	predicate := [ :candidate |
		             | code |
		             code := candidate asInteger.
		             code > 255
			             ifTrue: [ tested value: candidate ]
			             ifFalse: [ (table at: code + 1) = 1 ] ]
]
