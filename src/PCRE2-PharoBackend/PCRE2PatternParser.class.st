"
Recursive-descent parser for the Pharo backend. Produces executable pattern nodes and capture metadata while preserving PCRE2 matching order. Syntax errors and unsupported features are reported separately.
"
Class {
	#name : 'PCRE2PatternParser',
	#superclass : 'Object',
	#instVars : [
		'input',
		'pattern',
		'position',
		'options',
		'captureCount',
		'names',
		'groups',
		'depth',
		'references',
		'nestLimit',
		'lookbehindLimit'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'parsing' }
PCRE2PatternParser >> alternation [

	| alternatives |
	alternatives := OrderedCollection with: self sequence.
	self skipIgnored.
	[ self peek = $| ] whileTrue: [
			position := position + 1.
			alternatives add: self sequence.
			self skipIgnored ].
	alternatives size = 1 ifTrue: [ ^ alternatives first ].
	^ PCRE2AlternativeNode new children: alternatives asArray
]

{ #category : 'parsing' }
PCRE2PatternParser >> assertion: kind [

	| multiline dollarEndOnly word |
	multiline := (options bitAnd: PCRE2 multiline) ~= 0.
	dollarEndOnly := (options bitAnd: PCRE2 dollarEndOnly) ~= 0.
	word := self predicateFor: $w.
	^ PCRE2AssertionNode new predicate: [ :engine :state |
			  | index size left right |
			  index := state position.
			  size := engine subject size.
			  kind = #beginSubject
				  ifTrue: [ index = 0 ]
				  ifFalse: [
						  kind = #endSubject
							  ifTrue: [ index = size ]
							  ifFalse: [
									  kind = #startMatch
										  ifTrue: [ index = engine initialPosition ]
										  ifFalse: [
												  kind = #resetStart
													  ifTrue: [
															  state captures at: 1 put: index.
															  true ]
													  ifFalse: [
															  kind = #beginLine
																  ifTrue: [
																		  (index = 0 and: [ (engine matchOptions bitAnd: PCRE2 notBOL) = 0 ]) or: [
																			  multiline and: [ index > 0 and: [ index < size and: [ (engine subject at: index) = Character lf ] ] ] ] ]
																  ifFalse: [
																		  kind = #endLine
																			  ifTrue: [
																					  (engine matchOptions bitAnd: PCRE2 notEOL) = 0 and: [
																							  index = size or: [
																									  index < size and: [
																										  (engine subject at: index + 1) = Character lf and: [
																											  multiline or: [ dollarEndOnly not and: [ index = (size - 1) ] ] ] ] ] ] ]
																			  ifFalse: [
																					  kind = #endBeforeFinalNewline
																						  ifTrue: [ index = size or: [ index = (size - 1) and: [ engine subject last = Character lf ] ] ]
																						  ifFalse: [
																								  left := index > 0 and: [ word value: (engine subject at: index) ].
																								  right := index < size and: [ word value: (engine subject at: index + 1) ].
																								  left ~= right = (kind = #wordBoundary) ] ] ] ] ] ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> atEnd [

	^ position > pattern size
]

{ #category : 'parsing' }
PCRE2PatternParser >> atom [

	| character dotAll |
	character := self next.
	character = $( ifTrue: [ ^ self group ].
	character = $[ ifTrue: [ ^ self characterClass ].
	character = $\ ifTrue: [ ^ self escapeInClass: false ].
	character = $. ifTrue: [
			dotAll := (options bitAnd: PCRE2 dotAll) ~= 0.
			^ PCRE2CharacterNode new predicate: [ :candidate | dotAll or: [ candidate ~= Character lf ] ] ].
	character = $^ ifTrue: [ ^ self assertion: #beginLine ].
	character = $$ ifTrue: [ ^ self assertion: #endLine ].
	('*+?' includes: character) ifTrue: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
	^ self literal: character
]

{ #category : 'private' }
PCRE2PatternParser >> captureCount [

	^ captureCount
]

{ #category : 'private' }
PCRE2PatternParser >> captureCount: aValue [

	captureCount := aValue
]

{ #category : 'parsing' }
PCRE2PatternParser >> characterClass [

	| negative predicates first node end caseless |
	negative := self peek = $^.
	negative ifTrue: [ position := position + 1 ].
	predicates := OrderedCollection new.
	first := true.
	self skipClassIgnored.
	[ self atEnd not and: [ self peek ~= $] or: [ first ] ] ] whileTrue: [
			node := self classElement.
			(node isKindOf: PCRE2CharacterNode) ifFalse: [ self unsupported: 'this character-class escape' ].
			self skipClassIgnored.
			(self peek = $- and: [ position < pattern size and: [ (pattern at: position + 1) ~= $] ] ])
				ifTrue: [
						position := position + 1.
						self skipClassIgnored.
						self peek = $]
							ifTrue: [
									predicates add: node predicate.
									predicates add: (self literal: $-) predicate ]
							ifFalse: [
									end := self classElement.
									(end isKindOf: PCRE2CharacterNode) ifFalse: [ self unsupported: 'this range endpoint' ].
									(node character isNil or: [ end character isNil ]) ifTrue: [ self syntaxError: 'invalid range endpoint' ].
									node character > end character ifTrue: [ self syntaxError: 'range out of order in character class' ].
									caseless := (options bitAnd: PCRE2 caseless) ~= 0.
									predicates add: (self rangeFrom: node character to: end character caseless: caseless) ] ]
				ifFalse: [ predicates add: node predicate ].
			first := false.
			self skipClassIgnored ].
	self expect: $].
	^ PCRE2CharacterNode new predicate: [ :candidate |
		  (predicates anySatisfy: [ :predicate | predicate value: candidate ]) ~= negative ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> classElement [

	| character property closing |
	character := self next.
	character = $\ ifTrue: [ ^ self escapeInClass: true ].
	(character = $[ and: [ self peek = $: ]) ifTrue: [
			closing := pattern findString: ':]' startingAt: position + 1.
			closing > 0 ifTrue: [
					property := pattern copyFrom: position + 1 to: closing - 1.
					position := closing + 2.
					^ PCRE2CharacterNode new predicate: (self propertyPredicate: property) ] ].
	^ self literal: character
]

{ #category : 'parsing' }
PCRE2PatternParser >> decimal [

	| value |
	value := 0.
	[ self peek notNil and: [ self peek between: $0 and: $9 ] ] whileTrue: [
		value := value * 10 + self next asciiValue - $0 asciiValue ].
	^ value
]

{ #category : 'parsing' }
PCRE2PatternParser >> escapeInClass: inClass [

	| character reference delimiter start nodes property predicate |
	character := self next.
	('dDsSwWhHvV' includes: character) ifTrue: [ ^ PCRE2CharacterNode new predicate: (self predicateFor: character) ].
	character = $n ifTrue: [ ^ self literal: Character lf ].
	character = $r ifTrue: [ ^ self literal: Character cr ].
	character = $t ifTrue: [ ^ self literal: Character tab ].
	character = $f ifTrue: [ ^ self literal: Character newPage ].
	character = $a ifTrue: [ ^ self literal: (Character value: 7) ].
	character = $e ifTrue: [ ^ self literal: (Character value: 27) ].
	character = $x ifTrue: [ ^ self hexadecimalEscape ].
	character = $b ifTrue: [
			^ inClass
				  ifTrue: [ self literal: (Character value: 8) ]
				  ifFalse: [ self assertion: #wordBoundary ] ].
	character = $B ifTrue: [ ^ self assertion: #notWordBoundary ].
	character = $A ifTrue: [ ^ self assertion: #beginSubject ].
	character = $z ifTrue: [ ^ self assertion: #endSubject ].
	character = $Z ifTrue: [ ^ self assertion: #endBeforeFinalNewline ].
	character = $G ifTrue: [ ^ self assertion: #startMatch ].
	character = $K ifTrue: [ ^ self assertion: #resetStart ].
	character = $N ifTrue: [
			self peek = (Character value: 123) ifTrue: [ self unsupported: '\N{...}' ].
			^ PCRE2CharacterNode new predicate: [ :candidate | candidate ~= Character lf ] ].
	(character = $p or: [ character = $P ]) ifTrue: [
			property := self peek = (Character value: 123)
				            ifTrue: [
						            position := position + 1.
						            self readUntil: $} ]
				            ifFalse: [ self next asString ].
			predicate := self propertyPredicate: property.
			character = $P ifTrue: [ ^ PCRE2CharacterNode new predicate: [ :candidate | (predicate value: candidate) not ] ].
			^ PCRE2CharacterNode new predicate: predicate ].
	(character between: $1 and: $9) ifTrue: [ ^ self numericEscapeInClass: inClass ].
	character = $0 ifTrue: [
			position := position - 1.
			^ self octalEscape ].
	(character = $k or: [ character = $g ]) ifTrue: [
			inClass ifTrue: [ ^ self literal: character ].
			delimiter := self peek.
			(delimiter = $< or: [ delimiter = $' or: [ delimiter = (Character value: 123) ] ])
				ifTrue: [
						position := position + 1.
						delimiter := delimiter = $<
							             ifTrue: [ $> ]
							             ifFalse: [
									             delimiter = (Character value: 123)
										             ifTrue: [ $} ]
										             ifFalse: [ $' ] ].
						reference := self normalizedReference: (self readUntil: delimiter) ]
				ifFalse: [
						start := position.
						(self peek = $- or: [ self peek = $+ ]) ifTrue: [ position := position + 1 ].
						self decimal.
						reference := self normalizedReference: (pattern copyFrom: start to: position - 1) ].
			references add: reference.
			^ (character = $g and: [ delimiter = $> or: [ delimiter = $' ] ])
				  ifTrue: [ PCRE2SubroutineNode new reference: reference ]
				  ifFalse: [
						  PCRE2BackreferenceNode new
							  reference: reference;
							  options: options ] ].
	character = $E ifTrue: [ ^ PCRE2SequenceNode new children: #(  ) ].
	character = $Q ifTrue: [
			start := position.
			[ self atEnd not and: [ (self peek = $\ and: [ position < pattern size and: [ (pattern at: position + 1) = $E ] ]) not ] ]
				whileTrue: [ position := position + 1 ].
			nodes := (pattern copyFrom: start to: position - 1) collect: [ :literal | self literal: literal ] as: Array.
			self atEnd ifFalse: [ position := position + 2 ].
			^ PCRE2QuotedSequenceNode new children: nodes ].
	character isAlphaNumeric ifTrue: [ self unsupported: 'escape \' , character asString ].
	^ self literal: character
]

{ #category : 'parsing' }
PCRE2PatternParser >> expect: character [

	self next = character ifFalse: [ self syntaxError: 'expected ' , character asString ]
]

{ #category : 'matching' }
PCRE2PatternParser >> group [

	| savedOptions index name body character positive capture |
	savedOptions := options.
	index := nil.
	capture := (options bitAnd: PCRE2 noAutoCapture) = 0.
	self peek = $* ifTrue: [ self unsupported: 'backtracking control verbs' ].
	self peek = $? ifTrue: [
			position := position + 1.
			character := self next.
			character = $# ifTrue: [
					self readUntil: $).
					^ PCRE2SequenceNode new children: #(  ) ].
			character = $: ifTrue: [ ^ self groupBodyRestoring: savedOptions ].
			(character = $= or: [ character = $! ]) ifTrue: [
					positive := character = $=.
					body := self groupBodyRestoring: savedOptions.
					^ PCRE2LookaheadNode new
						  child: body;
						  positive: positive ].
			character = $> ifTrue: [ ^ PCRE2AtomicNode new child: (self groupBodyRestoring: savedOptions) ].
			character = $< ifTrue: [
					(self peek = $= or: [ self peek = $! ]) ifTrue: [
							positive := self next = $=.
							^ self lookbehind: (self groupBodyRestoring: savedOptions) positive: positive ].
					name := self readUntil: $> ].
			character = $' ifTrue: [ name := self readUntil: $' ].
			character = $P ifTrue: [
					self peek = $> ifTrue: [
							position := position + 1.
							name := self readUntil: $).
							references add: name.
							^ PCRE2SubroutineNode new reference: name ].
					self peek = $= ifTrue: [
							position := position + 1.
							^ PCRE2BackreferenceNode new
								  reference: (self readUntil: $));
								  options: options ].
					self expect: $<.
					name := self readUntil: $> ].
			character = $R ifTrue: [
					self expect: $).
					^ PCRE2SubroutineNode new reference: 0 ].
			character = $& ifTrue: [ ^ PCRE2SubroutineNode new reference: (self readUntil: $)) ].
			(character between: $0 and: $9) ifTrue: [
					position := position - 1.
					index := self decimal.
					self expect: $).
					^ PCRE2SubroutineNode new reference: index ].
			((character = $- or: [ character = $+ ]) and: [ self peek isNotNil and: [ self peek isDigit ] ]) ifTrue: [
					name := character asString , self decimal asString.
					index := self normalizedReference: name.
					self expect: $).
					references add: index.
					^ PCRE2SubroutineNode new reference: index ].
			name ifNil: [
					('imsxUJ-' includes: character) ifTrue: [
							position := position - 1.
							self inlineOptions.
							self peek = $) ifTrue: [
									position := position + 1.
									^ PCRE2SequenceNode new children: #(  ) ].
							self expect: $:.
							^ self groupBodyRestoring: savedOptions ].
					self unsupported: 'group (? ' , character asString ].
			capture := true ].
	capture ifFalse: [ ^ self groupBodyRestoring: savedOptions ].
	captureCount := captureCount + 1.
	index := captureCount.
	name ifNotNil: [
			name isEmpty ifTrue: [ self syntaxError: 'empty capture name' ].
			((names includes: name) and: [ (options bitAnd: PCRE2 dupNames) = 0 ]) ifTrue: [ self syntaxError: 'duplicate capture name' ].
			names at: index put: name ].
	body := PCRE2CaptureNode new index: index.
	groups at: index put: body.
	body child: (self groupBodyRestoring: savedOptions).
	^ body
]

{ #category : 'backends' }
PCRE2PatternParser >> groupBodyRestoring: savedOptions [

	| body |
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		body := self alternation.
		self expect: $) ] ensure: [
			depth := depth - 1.
			options := savedOptions ].
	^ body
]

{ #category : 'private' }
PCRE2PatternParser >> groups [

	^ groups
]

{ #category : 'private' }
PCRE2PatternParser >> groups: aValue [

	groups := aValue
]

{ #category : 'parsing' }
PCRE2PatternParser >> hexadecimalEscape [

	| digits codePoint |
	self peek = (Character value: 123)
		ifTrue: [
				position := position + 1.
				digits := self readUntil: $} ]
		ifFalse: [
				digits := String streamContents: [ :stream |
					          2 timesRepeat: [
						          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ] ].
	(digits isEmpty or: [ digits anySatisfy: [ :character | (character digitValue between: 0 and: 15) not ] ]) ifTrue: [
		self syntaxError: 'hexadecimal digit expected' ].
	codePoint := Integer readFrom: digits readStream base: 16.
	codePoint > 16r10FFFF ifTrue: [ self syntaxError: 'character code point too large' ].
	^ self literal: (Character value: codePoint)
]

{ #category : 'parsing' }
PCRE2PatternParser >> inlineOptions [

	| remove flags character flag seenX |
	remove := false.
	seenX := 0.
	flags := Dictionary newFrom: {
			         ($i -> PCRE2 caseless).
			         ($m -> PCRE2 multiline).
			         ($s -> PCRE2 dotAll).
			         ($x -> PCRE2 extended).
			         ($U -> PCRE2 ungreedy).
			         ($J -> PCRE2 dupNames) }.
	[ self atEnd not and: [ self peek ~= $: and: [ self peek ~= $) ] ] ] whileTrue: [
			character := self next.
			character = $-
				ifTrue: [ remove := true ]
				ifFalse: [
						flag := flags at: character ifAbsent: [ self unsupported: 'inline option ' , character asString ].
						character = $x ifTrue: [
								seenX := seenX + 1.
								(remove or: [ seenX > 1 ]) ifTrue: [ flag := flag bitOr: PCRE2 extendedMore ] ].
						options := remove
							           ifTrue: [ options bitAnd: flag bitInvert ]
							           ifFalse: [ options bitOr: flag ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> literal: character [

	| caseless |
	caseless := (options bitAnd: PCRE2 caseless) ~= 0.
	^ PCRE2CharacterNode new
		  character: character;
		  predicate: [ :candidate |
				  candidate = character or: [
						  caseless and: [ candidate asUppercase = character asUppercase or: [ candidate asLowercase = character asLowercase ] ] ] ]
]

{ #category : 'matching' }
PCRE2PatternParser >> lookbehind: body positive: positive [

	| branches |
	branches := body lookbehindBranches.
	branches do: [ :branch |
			branch maximumLength ifNil: [ self unsupported: 'unbounded lookbehind' ].
			(branch maximumLength > lookbehindLimit and: [ branch minimumLength ~= branch maximumLength ]) ifTrue: [
				self syntaxError: 'lookbehind is too long' ] ].
	^ PCRE2LookbehindNode new
		  branches: branches;
		  positive: positive
]

{ #category : 'configuration' }
PCRE2PatternParser >> lookbehindLimit: anInteger [

	lookbehindLimit := anInteger
]

{ #category : 'private' }
PCRE2PatternParser >> names [

	^ names
]

{ #category : 'private' }
PCRE2PatternParser >> names: aValue [

	names := aValue
]

{ #category : 'configuration' }
PCRE2PatternParser >> nestLimit: anInteger [

	nestLimit := anInteger
]

{ #category : 'parsing' }
PCRE2PatternParser >> next [

	| character |
	self atEnd ifTrue: [ self syntaxError: 'unexpected end of pattern' ].
	character := pattern at: position.
	position := position + 1.
	^ character
]

{ #category : 'parsing' }
PCRE2PatternParser >> normalizedReference: text [

	| trimmed number |
	trimmed := text trimBoth.
	trimmed isEmpty ifTrue: [ self syntaxError: 'empty reference' ].
	((trimmed first isDigit or: [ trimmed first = $- or: [ trimmed first = $+ ] ]) and: [
		 trimmed allSatisfy: [ :character | character isDigit or: [ character = $- or: [ character = $+ ] ] ] ]) ifFalse: [ ^ trimmed ].
	number := [ trimmed asInteger ]
		          on: Error
		          do: [ :error | self syntaxError: 'invalid subpattern reference' ].
	trimmed first = $- ifTrue: [ ^ captureCount + number + 1 ].
	trimmed first = $+ ifTrue: [ ^ captureCount + number ].
	^ number
]

{ #category : 'parsing' }
PCRE2PatternParser >> numericEscapeInClass: inClass [

	| saved reference |
	position := position - 1.
	inClass ifTrue: [ ^ self octalEscape ].
	saved := position.
	reference := self decimal.
	(reference < 10 or: [ reference <= captureCount ]) ifTrue: [
			references add: reference.
			^ PCRE2BackreferenceNode new
				  reference: reference;
				  options: options ].
	position := saved.
	^ self octalEscape
]

{ #category : 'parsing' }
PCRE2PatternParser >> octalEscape [

	| value count |
	value := 0.
	count := 0.
	[ count < 3 and: [ self peek isNotNil and: [ self peek between: $0 and: $7 ] ] ] whileTrue: [
			value := value * 8 + self next asciiValue - $0 asciiValue.
			count := count + 1 ].
	^ self literal: (Character value: value)
]

{ #category : 'parsing' }
PCRE2PatternParser >> parse [

	| result |
	result := self alternation.
	self skipIgnored.
	self atEnd ifFalse: [ self syntaxError: 'unmatched closing parenthesis' ].
	references do: [ :reference |
			(reference isInteger
				 ifTrue: [ reference > captureCount or: [ reference < 0 ] ]
				 ifFalse: [ (names includes: reference) not ]) ifTrue: [ self syntaxError: 'reference to non-existent subpattern' ] ].
	^ result
]

{ #category : 'parsing' }
PCRE2PatternParser >> parse: preparedInput options: compileOptions [

	input := preparedInput.
	pattern := input readFrom: 1 to: input size.
	pattern isString ifFalse: [ pattern := pattern asString ].
	position := 1.
	options := compileOptions.
	captureCount := 0.
	names := Dictionary new.
	groups := Dictionary new.
	depth := 0.
	nestLimit ifNil: [ nestLimit := 250 ].
	lookbehindLimit ifNil: [ lookbehindLimit := 255 ].
	references := OrderedCollection new.
	(options bitAnd: PCRE2 literal) ~= 0 ifTrue: [
		^ PCRE2SequenceNode new children: (pattern collect: [ :character | self literal: character ] as: Array) ].
	^ self parse
]

{ #category : 'parsing' }
PCRE2PatternParser >> peek [

	^ self atEnd ifFalse: [ pattern at: position ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> piece [

	| node minimum maximum greedy repeat quantifier bounds |
	node := self atom.
	self skipIgnored.
	quantifier := self peek.
	quantifier = $* ifTrue: [
			minimum := 0.
			position := position + 1 ].
	quantifier = $+ ifTrue: [
			minimum := 1.
			position := position + 1 ].
	quantifier = $? ifTrue: [
			minimum := 0.
			maximum := 1.
			position := position + 1 ].
	quantifier = (Character value: 123) ifTrue: [
			bounds := self quantifierBounds.
			bounds ifNotNil: [
					minimum := bounds first.
					maximum := bounds second ] ].
	minimum ifNil: [ ^ node ].
	self skipIgnored.
	greedy := (options bitAnd: PCRE2 ungreedy) = 0.
	self peek = $? ifTrue: [
			greedy := greedy not.
			position := position + 1 ].
	repeat := node repeatMinimum: minimum maximum: maximum greedy: greedy.
	self peek = $+ ifTrue: [
			position := position + 1.
			^ PCRE2AtomicNode new child: repeat ].
	^ repeat
]

{ #category : 'parsing' }
PCRE2PatternParser >> predicateFor: character [

	| predicate unicode |
	unicode := (options bitAnd: PCRE2 ucp) ~= 0.
	character asLowercase = $d ifTrue: [
			predicate := unicode
				             ifTrue: [ [ :candidate | candidate isDigit ] ]
				             ifFalse: [ [ :candidate | candidate between: $0 and: $9 ] ] ].
	character asLowercase = $w ifTrue: [
			predicate := unicode
				             ifTrue: [
						             [ :candidate |
							             candidate isLetter or: [
									             candidate isDigit or: [
											             (Unicode isLetterNumber: candidate) or: [
												             (Unicode isOtherNumber: candidate) or: [
													             (Unicode isNonspacingMark: candidate) or: [ Unicode isConnectorPunctuation: candidate ] ] ] ] ] ] ]
				             ifFalse: [
						             [ :candidate |
							             (candidate between: $a and: $z) or: [
								             (candidate between: $A and: $Z) or: [ (candidate between: $0 and: $9) or: [ candidate = $_ ] ] ] ] ] ].
	character asLowercase = $s ifTrue: [
			predicate := unicode
				             ifTrue: [ [ :candidate | candidate isSeparator ] ]
				             ifFalse: [ [ :candidate | #( 9 10 11 12 13 32 ) includes: candidate asInteger ] ] ].
	character asLowercase = $h ifTrue: [
			predicate := [ :candidate |
			             #( 9 32 160 5760 6158 8192 8193 8194 8195 8196 8197 8198 8199 8200 8201 8202 8239 8287 12288 ) includes:
				             candidate asInteger ] ].
	character asLowercase = $v ifTrue: [ predicate := [ :candidate | #( 10 11 12 13 133 8232 8233 ) includes: candidate asInteger ] ].
	character isUppercase ifTrue: [ ^ [ :candidate | (predicate value: candidate) not ] ].
	^ predicate
]

{ #category : 'parsing' }
PCRE2PatternParser >> propertyPredicate: property [
	"shortcut: Uses Pharo Unicode data; replace with pinned PCRE2 tables before claiming Unicode parity."

	| normalized |
	normalized := property asLowercase.
	((#( 'lu' 'll' 'lt' 'uppercase_letter' 'lowercase_letter' 'titlecase_letter' ) includes: normalized) and: [
		 (options bitAnd: PCRE2 caseless) ~= 0 ]) ifTrue: [
		^ [ :character | character isUppercase or: [ character isLowercase or: [ Unicode isTitlecaseLetter: character ] ] ] ].
	(#( 'lt' 'titlecase_letter' ) includes: normalized) ifTrue: [ ^ [ :character | Unicode isTitlecaseLetter: character ] ].
	(#( 'n' 'number' ) includes: normalized) ifTrue: [
		^ [ :character | character isDigit or: [ (Unicode isLetterNumber: character) or: [ Unicode isOtherNumber: character ] ] ] ].
	(#( 'm' 'mark' ) includes: normalized) ifTrue: [
			^ [ :character |
				  (Unicode isNonspacingMark: character) or: [
					  (Unicode isSpacingCombiningMark: character) or: [ Unicode isEnclosingMark: character ] ] ] ].
	normalized = 'mn' ifTrue: [ ^ [ :character | Unicode isNonspacingMark: character ] ].
	normalized = 'pc' ifTrue: [ ^ [ :character | Unicode isConnectorPunctuation: character ] ].
	(#( 'l' 'letter' 'alpha' ) includes: normalized) ifTrue: [ ^ [ :character | character isLetter ] ].
	(#( 'nd' 'decimal_number' 'digit' ) includes: normalized) ifTrue: [ ^ [ :character | character isDigit ] ].
	(#( 'lu' 'uppercase_letter' 'upper' ) includes: normalized) ifTrue: [ ^ [ :character | character isUppercase ] ].
	(#( 'll' 'lowercase_letter' 'lower' ) includes: normalized) ifTrue: [ ^ [ :character | character isLowercase ] ].
	(#( 'space' 'whitespace' ) includes: normalized) ifTrue: [ ^ [ :character | character isSeparator ] ].
	(#( 'z' 'separator' ) includes: normalized) ifTrue: [
			^ [ :character |
			  (Unicode isSpaceSeparator: character) or: [
				  (Unicode isLineSeparator: character) or: [ Unicode isParagraphSeparator: character ] ] ] ].
	normalized = 'ascii' ifTrue: [ ^ [ :character | character asInteger < 128 ] ].
	normalized = 'any' ifTrue: [ ^ [ :character | true ] ].
	normalized = 'word' ifTrue: [ ^ self predicateFor: $w ].
	normalized = 'alnum' ifTrue: [ ^ [ :character | character isAlphaNumeric ] ].
	normalized = 'xdigit' ifTrue: [ ^ [ :character | character digitValue between: 0 and: 15 ] ].
	self unsupported: 'Unicode property ' , property
]

{ #category : 'parsing' }
PCRE2PatternParser >> quantifierBounds [

	| saved minimum maximum hasMinimum hasComma |
	saved := position.
	position := position + 1.
	self skipQuantifierSpaces.
	hasMinimum := self peek isNotNil and: [ self peek between: $0 and: $9 ].
	minimum := hasMinimum
		           ifTrue: [ self decimal ]
		           ifFalse: [ 0 ].
	maximum := minimum.
	self skipQuantifierSpaces.
	hasComma := self peek = $,.
	hasComma ifTrue: [
			position := position + 1.
			self skipQuantifierSpaces.
			maximum := (self peek isNotNil and: [ self peek between: $0 and: $9 ]) ifTrue: [ self decimal ].
			self skipQuantifierSpaces ].
	(self peek ~= $} or: [ hasMinimum not and: [ hasComma not or: [ maximum isNil ] ] ]) ifTrue: [
			position := saved.
			^ nil ].
	position := position + 1.
	(maximum isNotNil and: [ minimum > maximum ]) ifTrue: [ self syntaxError: 'numbers out of order in quantifier' ].
	(minimum > 65535 or: [ maximum isNotNil and: [ maximum > 65535 ] ]) ifTrue: [ self syntaxError: 'number too big in quantifier' ].
	^ {
		  minimum.
		  maximum }
]

{ #category : 'parsing' }
PCRE2PatternParser >> rangeFrom: low to: high caseless: caseless [

	^ [ :candidate |
		  (candidate between: low and: high) or: [
			  caseless and: [ (candidate asUppercase between: low and: high) or: [ candidate asLowercase between: low and: high ] ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> readUntil: delimiter [

	| start |
	start := position.
	[ self atEnd not and: [ self peek ~= delimiter ] ] whileTrue: [ position := position + 1 ].
	self atEnd ifTrue: [ self syntaxError: 'missing delimiter' ].
	position := position + 1.
	^ pattern copyFrom: start to: position - 2
]

{ #category : 'parsing' }
PCRE2PatternParser >> sequence [

	| nodes |
	nodes := OrderedCollection new.
	self skipIgnored.
	[ self atEnd not and: [ self peek ~= $) and: [ self peek ~= $| ] ] ] whileTrue: [
			nodes add: self piece.
			self skipIgnored ].
	^ PCRE2SequenceNode new children: nodes asArray
]

{ #category : 'parsing' }
PCRE2PatternParser >> skipClassIgnored [

	| consumed |
	[
		consumed := false.
		(pattern findString: '\E' startingAt: position) = position ifTrue: [
				position := position + 2.
				consumed := true ].
		(pattern findString: '\Q\E' startingAt: position) = position ifTrue: [
				position := position + 4.
				consumed := true ].
		((options bitAnd: PCRE2 extendedMore) ~= 0 and: [ self peek = Character space or: [ self peek = Character tab ] ]) ifTrue: [
				position := position + 1.
				consumed := true ].
		consumed ] whileTrue
]

{ #category : 'parsing' }
PCRE2PatternParser >> skipIgnored [

	| extended consumed |
	extended := (options bitAnd: (PCRE2 extended bitOr: PCRE2 extendedMore)) ~= 0.
	[
		consumed := false.
		(pattern findString: '(?#' startingAt: position) = position ifTrue: [
				position := position + 3.
				self readUntil: $).
				consumed := true ].
		(extended and: [ self atEnd not and: [ self peek isSeparator or: [ self peek = $# ] ] ]) ifTrue: [
				self peek = $#
					ifTrue: [ [ self atEnd not and: [ self next ~= Character lf ] ] whileTrue ]
					ifFalse: [ position := position + 1 ].
				consumed := true ].
		consumed ] whileTrue
]

{ #category : 'parsing' }
PCRE2PatternParser >> skipQuantifierSpaces [

	[ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ position := position + 1 ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> syntaxError: message [

	| prefix offset |
	prefix := pattern copyFrom: 1 to: (position - 1 min: pattern size).
	offset := (input class fromString: prefix) size.
	PCRE2CompileError signal: message in: input at: offset
]

{ #category : 'parsing' }
PCRE2PatternParser >> unsupported: feature [

	PCRE2UnsupportedFeature signal: 'Pharo backend does not yet support ' , feature
]
