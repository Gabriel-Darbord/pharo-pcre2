"
The dot. Matches one character, excluding the line terminators of the newline convention unless the pattern was compiled with dotall.
"
Class {
	#name : 'PCRE2DotNode',
	#superclass : 'PCRE2PatternNode',
	#instVars : [
		'convention',
		'dotAll'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2DotNode >> acceptsAt: offset in: subject [
	"Whether the dot matches here. Only the newline convention can refuse, and it is read from the subject rather than from the character."

	dotAll ifTrue: [ ^ true ].
	^ ((convention lengthAt: offset + 1 in: subject) > 0 or: [
		   convention mode = PCRE2 newlineCRLF and: [ (convention lengthEndingAt: offset + 1 in: subject) = 2 ] ]) not
]

{ #category : 'optimization' }
PCRE2DotNode >> acceptsEveryCharacter [

	^ dotAll
]

{ #category : 'optimization' }
PCRE2DotNode >> acceptsEveryCharacterButLineEnds [

	^ dotAll not
]

{ #category : 'generating' }
PCRE2DotNode >> asciiTable [
	"The dot accepts every byte but the line terminators of its convention, which a table can say as long as the convention decides from one character."

	| table excluded |
	table := ByteArray new: 256 withAll: 1.
	dotAll ifTrue: [ ^ table ].
	excluded := self excludedNewlineCodes ifNil: [ ^ nil ].
	excluded do: [ :code | table at: code + 1 put: 0 ].
	^ table
]

{ #category : 'optimization' }
PCRE2DotNode >> canAutoPossess [

	^ true
]

{ #category : 'matching' }
PCRE2DotNode >> convention: policy dotAll: boolean [

	convention := policy.
	dotAll := boolean
]

{ #category : 'matching' }
PCRE2DotNode >> countIn: anEngine from: offset limit: maximum [
	"How many characters in a row from this offset are accepted, at most maximum of them, where the run stopped, and the last offset read. The dot judges a position from the newline convention before reading it, so the one that ends the run was not read."

	| subject size position count read |
	subject := anEngine subject.
	size := subject size.
	position := offset.
	count := 0.
	read := nil.
	[ (maximum isNil or: [ count < maximum ]) and: [ position < size ] ] whileTrue: [
			(self acceptsAt: position in: subject) ifFalse: [
					^ {
						  count.
						  position.
						  read } ].
			read := position.
			position := subject nextOffsetFrom: position.
			count := count + 1 ].
	^ {
		  count.
		  position.
		  read }
]

{ #category : 'generating' }
PCRE2DotNode >> excludedNewlineCodes [
	"The codes under 128 this convention counts as a line terminator, or nil when it reads more than one character to decide, as CRLF does."

	| mode |
	mode := convention mode.
	mode = PCRE2 newlineLF ifTrue: [ ^ #( 10 ) ].
	mode = PCRE2 newlineCR ifTrue: [ ^ #( 13 ) ].
	mode = PCRE2 newlineNul ifTrue: [ ^ #( 0 ) ].
	mode = PCRE2 newlineAnyCRLF ifTrue: [ ^ #( 10 13 ) ].
	mode = PCRE2 newlineAny ifTrue: [ ^ #( 10 11 12 13 ) ].
	^ nil
]

{ #category : 'matching' }
PCRE2DotNode >> executeIn: engine state: state [

	state position >= engine subject size ifTrue: [
			engine notePartial: state.
			^ nil ].
	(self acceptsAt: state position in: engine subject) ifFalse: [ ^ nil ].
	engine noteInspectionAt: state position.
	state position: (engine subject nextOffsetFrom: state position).
	^ state
]

{ #category : 'testing' }
PCRE2DotNode >> isSingleCharacter [

	^ true
]

{ #category : 'accessing' }
PCRE2DotNode >> maximumLength [

	^ 1
]

{ #category : 'accessing' }
PCRE2DotNode >> minimumLength [

	^ 1
]
