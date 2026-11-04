"
One character position, accepted by a predicate. A single literal also keeps its character for the start optimizations and auto-possessification; a class keeps a table of the codes under 256 it accepts, since it is asked once for every character of the subject.
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
	"The codes under 256 the predicate accepts, built by asking the predicate so the two cannot disagree."

	| table |
	table := ByteArray new: 256.
	0 to: 255 do: [ :code | (aPredicate value: (PCRE2CodeUnit fromInteger: code)) ifTrue: [ table at: code + 1 put: 1 ] ].
	^ table
]

{ #category : 'matching' }
PCRE2CharacterNode >> acceptsCode: code [
	"Whether this item matches the character with this code. The table holds small integers, so == is a test rather than a message send."

	(table isNil or: [ code > 255 ]) ifTrue: [ ^ predicate value: (PCRE2CodeUnit fromInteger: code) ].
	^ (table at: code + 1) == 1
]

{ #category : 'generating' }
PCRE2CharacterNode >> asciiTable [
	"A class answers the table it was compiled with; a single literal builds one here."

	^ table ifNil: [ self class tableFor: predicate ]
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

{ #category : 'accessing' }
PCRE2CharacterNode >> table [
	"The codes under 256 this item accepts, or nil for a single literal."

	^ table
]

{ #category : 'optimization' }
PCRE2CharacterNode >> tabulate [
	"Tabulate the codes under 256 this item accepts and wrap the predicate around the table, so every reader of it gains. Only worth it for a class: a single literal compares faster."

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
