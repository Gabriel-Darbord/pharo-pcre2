Class {
	#name : 'PCRE2ReplacementExpander',
	#superclass : 'Object',
	#instVars : [
		'backend',
		'match',
		'options',
		'expression',
		'position',
		'mode',
		'singleCase',
		'buffer',
		'output'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'expanding' }
PCRE2ReplacementExpander >> append: text active: active [

	active ifFalse: [ ^ self ].
	(singleCase isNotNil and: [ text isNotEmpty ]) ifTrue: [
			self flush.
			output nextPutAll: (backend transformCase: text first asString mode: singleCase).
			singleCase := nil.
			buffer nextPutAll: text allButFirst.
			^ self ].
	buffer nextPutAll: text
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> digits: base maximum: maximum [

	| start |
	start := position.
	[ self peek isNotNil and: [ position - start < maximum and: [ self peek digitValue between: 0 and: base - 1 ] ] ] whileTrue: [
		self next ].
	^ expression copyFrom: start to: position - 1
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> dollarActive: active [

	| character delimiter start reference value operator selected stop |
	character := self next.
	character = $$ ifTrue: [ ^ self append: '$' active: active ].
	(character = (Character value: 123) or: [ character = $< ])
		ifTrue: [
				delimiter := character = $<
					             ifTrue: [ $> ]
					             ifFalse: [ $} ].
				start := position.
				[ self peek isNotNil and: [ self peek ~= delimiter and: [ self peek ~= $: ] ] ] whileTrue: [ self next ].
				reference := expression copyFrom: start to: position - 1.
				self peek = $: ifTrue: [
						self extended ifFalse: [ PCRE2MatchError signal: 'invalid replacement string' ].
						self next.
						operator := self next.
						('+-' includes: operator) ifFalse: [ PCRE2MatchError signal: 'invalid replacement string' ].
						value := active ifTrue: [ backend conditionalValue: reference match: match options: options ].
						selected := active and: [ value isNotNil ].
						operator = $- ifTrue: [
								self append: (value ifNil: [ '' ]) active: selected.
								self parseUntil: #( $} ) active: (active and: [ selected not ]).
								self expect: $}.
								^ self ].
						stop := self parseUntil: #( $: $} ) active: selected.
						stop = $: ifTrue: [
								self next.
								self parseUntil: #( $} ) active: (active and: [ selected not ]) ].
						self expect: $}.
						^ self ].
				self expect: delimiter ]
		ifFalse: [
				start := position - 1.
				(character isAlphaNumeric and: [ character ~= $_ ]) ifTrue: [
						[
							self peek isNotNil and: [
									character isDigit
										ifTrue: [ self peek isDigit ]
										ifFalse: [ self peek isAlphaNumeric or: [ self peek = $_ ] ] ] ] whileTrue: [ self next ] ].
				reference := expression copyFrom: start to: position - 1 ].
	active ifTrue: [ self append: (backend replacementValue: reference match: match options: options) active: true ]
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> escapeActive: active [

	| character text start code |
	character := self next.
	('ULulE' includes: character) ifTrue: [
			active ifTrue: [
					self flush.
					character = $E ifTrue: [
							mode := #none.
							singleCase := nil ].
					character = $U ifTrue: [ mode := #upper ].
					character = $L ifTrue: [ mode := #lower ].
					character = $u ifTrue: [
							mode := #none.
							singleCase := #upper ].
					character = $l ifTrue: [
							mode := #none.
							singleCase := #lower ] ].
			^ self ].
	character = $Q ifTrue: [
			[ self peek isNotNil and: [ (expression findString: '\E' startingAt: position) ~= position ] ] whileTrue: [
				self append: self next asString active: active ].
			self peek ifNotNil: [ position := position + 2 ].
			^ self ].
	character = $g ifTrue: [
			self expect: $<.
			text := self readUntil: $>.
			active ifTrue: [ self append: (backend replacementValue: text match: match options: options) active: true ].
			^ self ].
	text := (Dictionary newFrom: {
			         ($n -> String lf).
			         ($r -> String cr).
			         ($t -> Character tab asString).
			         ($b -> (Character value: 8) asString).
			         ($v -> (Character value: 11) asString).
			         ($f -> Character newPage asString).
			         ($a -> (Character value: 7) asString).
			         ($e -> (Character value: 27) asString) }) at: character ifAbsent: [ nil ].
	text ifNotNil: [ ^ self append: text active: active ].
	character = $c ifTrue: [ ^ self append: (Character value: (self next asUppercase asInteger bitXor: 64)) asString active: active ].
	(character = $x or: [ character = $o ]) ifTrue: [
			self peek = (Character value: 123)
				ifTrue: [
						self next.
						text := (self readUntil: $}) trimBoth ]
				ifFalse: [
						character = $o ifTrue: [ PCRE2MatchError signal: 'missing opening brace in replacement' ].
						text := self digits: 16 maximum: 2 ].
			text isEmpty ifTrue: [ PCRE2MatchError signal: 'hexadecimal digit expected in replacement' ].
			code := [
				        Integer readFrom: text readStream base: (character = $x
						         ifTrue: [ 16 ]
						         ifFalse: [ 8 ]) ]
				        on: Error
				        do: [ :error | PCRE2MatchError signal: 'invalid character code in replacement' ].
			code > 16r10FFFF ifTrue: [ PCRE2MatchError signal: 'invalid character code in replacement' ].
			^ self append: (Character value: code) asString active: active ].
	character isDigit ifTrue: [
			position := position - 1.
			start := position.
			text := self digits: 10 maximum: 100.
			(text asInteger > 0 and: [ text asInteger < match ovectorCount ]) ifTrue: [
					active ifTrue: [ self append: (backend replacementValue: text match: match options: options) active: true ].
					^ self ].
			position := start.
			text := self digits: 8 maximum: 3.
			text isEmpty ifTrue: [ PCRE2MatchError signal: 'unknown substring' ].
			^ self append: (Character value: (Integer readFrom: text readStream base: 8)) asString active: active ].
	character isAlphaNumeric ifTrue: [ PCRE2MatchError signal: 'invalid escape sequence in replacement string' ].
	self append: character asString active: active
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> expand: text backend: implementation match: matchObject options: flags [

	expression := text.
	backend := implementation.
	match := matchObject.
	options := flags.
	position := 1.
	mode := #none.
	buffer := WriteStream on: String new.
	output := WriteStream on: String new.
	self parseUntil: #(  ) active: true.
	self flush.
	^ output contents
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> expect: character [

	self next = character ifFalse: [ PCRE2MatchError signal: 'invalid replacement string' ]
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> extended [

	^ (options bitAnd: PCRE2 substituteExtended) ~= 0
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> flush [

	| text |
	text := buffer contents.
	buffer reset.
	text isEmpty ifTrue: [ ^ self ].
	mode = #none ifFalse: [ text := backend transformCase: text mode: mode ].
	output nextPutAll: text
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> next [

	| character |
	character := self peek.
	character ifNil: [ PCRE2MatchError signal: 'invalid replacement string' ].
	position := position + 1.
	^ character
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> parseUntil: terminators active: active [

	[ self peek isNotNil and: [ (terminators includes: self peek) not ] ] whileTrue: [
			| character |
			character := self next.
			character = $$
				ifTrue: [ self dollarActive: active ]
				ifFalse: [
						(character = $\ and: [ self extended ])
							ifTrue: [ self escapeActive: active ]
							ifFalse: [ self append: character asString active: active ] ] ].
	^ self peek
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> peek [

	^ position <= expression size ifTrue: [ expression at: position ]
]

{ #category : 'expanding' }
PCRE2ReplacementExpander >> readUntil: delimiter [

	| start |
	start := position.
	[ self peek isNotNil and: [ self peek ~= delimiter ] ] whileTrue: [ self next ].
	self expect: delimiter.
	^ expression copyFrom: start to: position - 2
]
