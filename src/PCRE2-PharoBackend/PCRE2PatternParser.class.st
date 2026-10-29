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
		'lookbehindLimit',
		'lookbehinds',
		'newlineConvention',
		'bsr',
		'extraOptions',
		'calloutSites',
		'itemLengths',
		'codeUnitWidth',
		'patternOffsets',
		'compiledOptions',
		'patternMatchOptions',
		'patternLimits',
		'requiresPreviousCharacter'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'parsing' }
PCRE2PatternParser >> altBSUX [

	^ (options bitAnd: PCRE2 altBSUX) ~= 0 or: [ (extraOptions bitAnd: PCRE2 extraAltBsux) ~= 0 ]
]

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
PCRE2PatternParser >> asciiInlineOption [

	| flags |
	flags := Dictionary newFrom: {
			         ($D -> PCRE2 extraAsciiBsd).
			         ($S -> PCRE2 extraAsciiBss).
			         ($W -> PCRE2 extraAsciiBsw).
			         ($T -> PCRE2 extraAsciiDigit).
			         ($P -> (PCRE2 extraAsciiPosix | PCRE2 extraAsciiDigit)) }.
	(flags includesKey: self peek) ifTrue: [ ^ flags at: self next ].
	^ PCRE2 extraAsciiBsd | PCRE2 extraAsciiBss | PCRE2 extraAsciiBsw | PCRE2 extraAsciiDigit | PCRE2 extraAsciiPosix
]

{ #category : 'parsing' }
PCRE2PatternParser >> assertion: kind [

	| multiline dollarEndOnly word convention altCircumflex |
	(#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [ requiresPreviousCharacter := true ].
	multiline := (options bitAnd: PCRE2 multiline) ~= 0.
	dollarEndOnly := (options bitAnd: PCRE2 dollarEndOnly) ~= 0.
	altCircumflex := (options bitAnd: PCRE2 altCircumflex) ~= 0.
	word := self predicateFor: $w.
	convention := newlineConvention.
	^ PCRE2AssertionNode new
		  kind: kind;
		  predicate: [ :engine :state |
				  | index size newline beforeEnd |
				  index := state position.
				  size := engine subject size.
				  (index = size and: [ #( endLine endSubject endBeforeFinalNewline ) includes: kind ]) ifTrue: [ engine notePartial: state ].
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
																					  multiline and: [
																							  (index < size or: [ altCircumflex ]) and: [ (convention lengthEndingAt: index in: engine subject) > 0 ] ] ] ]
																	  ifFalse: [
																			  newline := convention lengthAt: index + 1 in: engine subject.
																			  beforeEnd := newline > 0 and: [ index + newline = size ].
																			  kind = #endBeforeFinalNewline
																				  ifTrue: [ index = size or: [ beforeEnd ] ]
																				  ifFalse: [
																						  kind = #endLine
																							  ifTrue: [
																									  (index = size and: [ (engine matchOptions bitAnd: PCRE2 notEOL) = 0 ]) or: [
																											  newline > 0 and: [
																													  multiline or: [
																															  beforeEnd and: [ dollarEndOnly not and: [ (engine matchOptions bitAnd: PCRE2 notEOL) = 0 ] ] ] ] ] ]
																							  ifFalse: [
																									  (index > 0 and: [ word value: (engine subject at: (engine subject previousOffsetFrom: index) + 1) ])
																									  ~= (index < size and: [ word value: (engine subject at: index + 1) ]) = (kind = #wordBoundary) ] ] ] ] ] ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> atEnd [

	^ position > pattern size
]

{ #category : 'parsing' }
PCRE2PatternParser >> atom [

	| character |
	character := self next.
	character = $( ifTrue: [ ^ self group ].
	character = $[ ifTrue: [ ^ self characterClass ].
	character = $\ ifTrue: [ ^ self escapeInClass: false ].
	character = $. ifTrue: [ ^ PCRE2DotNode new convention: newlineConvention dotAll: (options bitAnd: PCRE2 dotAll) ~= 0 ].
	character = $^ ifTrue: [ ^ self assertion: #beginLine ].
	character = $$ ifTrue: [ ^ self assertion: #endLine ].
	('*+?' includes: character) ifTrue: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
	^ self literal: character
]

{ #category : 'parsing' }
PCRE2PatternParser >> bracedOctalEscape [

	| digits |
	self expect: (Character value: 123).
	digits := (self readUntil: $}) trimBoth.
	(digits isEmpty or: [ digits anySatisfy: [ :character | (character between: $0 and: $7) not ] ]) ifTrue: [
		self syntaxError: 'non-octal character in \o{} (closing brace missing?)' ].
	^ self literalCodePoint: (Integer readFrom: digits readStream base: 8)
]

{ #category : 'parsing' }
PCRE2PatternParser >> branchResetRestoring: savedOptions [

	| base maximum alternatives |
	base := captureCount.
	maximum := base.
	alternatives := OrderedCollection new.
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		[
			captureCount := base.
			alternatives add: self sequence.
			maximum := maximum max: captureCount.
			self peek = $| ] whileTrue: [ position := position + 1 ].
		self expect: $) ] ensure: [
			captureCount := maximum.
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
	^ PCRE2AlternativeNode new children: alternatives asArray
]

{ #category : 'configuration' }
PCRE2PatternParser >> bsrMode [

	^ bsr
]

{ #category : 'callouts' }
PCRE2PatternParser >> calloutSites [

	^ calloutSites asArray
]

{ #category : 'callouts' }
PCRE2PatternParser >> calloutStringSize: text [

	(options bitAnd: PCRE2 utf) = 0 ifTrue: [ ^ text size ].
	codeUnitWidth = 8 ifTrue: [ ^ text asPCRE2UTF8Input size ].
	codeUnitWidth = 16 ifTrue: [ ^ text asPCRE2UTF16Input size ].
	^ text size
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
	self skipClassIgnored.
	negative := self peek = $^.
	negative ifTrue: [ position := position + 1 ].
	((options bitAnd: PCRE2 allowEmptyClass) ~= 0 and: [ self peek = $] ]) ifTrue: [
			self next.
			^ PCRE2CharacterNode new predicate: [ :candidate | negative ] ].
	predicates := OrderedCollection new.
	first := true.
	self skipClassIgnored.
	[ self atEnd not and: [ self peek ~= $] or: [ first ] ] ] whileTrue: [
			node := self classElement.
			(node isKindOf: PCRE2QuotedSequenceNode) ifTrue: [
					node children allButLast do: [ :quoted | predicates add: quoted predicate ].
					node := node children last ].
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
									(end isKindOf: PCRE2QuotedSequenceNode) ifTrue: [
											end children allButFirst do: [ :quoted | predicates add: quoted predicate ].
											end := end children first ].
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
PCRE2PatternParser >> classExpressionIgnored [

	[
		self skipClassIgnored.
		self peek isNotNil and: [ self peek isSeparator ] ] whileTrue: [ position := position + 1 ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> classIntersection [

	| left |
	left := self classOperand.
	self classExpressionIgnored.
	[ self peek = $& ] whileTrue: [
			self next.
			left := self combineClass: left with: self classOperand operator: $&.
			self classExpressionIgnored ].
	^ left
]

{ #category : 'parsing' }
PCRE2PatternParser >> classOperand [

	| character predicate node |
	self classExpressionIgnored.
	character := self next.
	character = $! ifTrue: [
			predicate := self classOperand.
			^ [ :candidate | (predicate value: candidate) not ] ].
	character = $( ifTrue: [
			predicate := self classUnion.
			self classExpressionIgnored.
			self expect: $).
			^ predicate ].
	character = $[ ifTrue: [
			self peek = $: ifTrue: [
					position := position - 1.
					^ self classElement predicate ].
			^ self characterClass predicate ].
	character = $\ ifTrue: [
			node := self escapeInClass: true.
			(node isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxError: 'invalid extended class operand' ].
			^ node predicate ].
	self syntaxError: 'expected an extended class operand'
]

{ #category : 'parsing' }
PCRE2PatternParser >> classUnion [

	| left right operator |
	left := self classIntersection.
	self classExpressionIgnored.
	[ self peek isNotNil and: [ '+|-^' includes: self peek ] ] whileTrue: [
			operator := self next.
			right := self classIntersection.
			left := self combineClass: left with: right operator: operator.
			self classExpressionIgnored ].
	^ left
]

{ #category : 'callouts' }
PCRE2PatternParser >> codeUnitOffsetAt: index [

	^ patternOffsets at: index
]

{ #category : 'callouts' }
PCRE2PatternParser >> codeUnitWidth: width [

	codeUnitWidth := width
]

{ #category : 'parsing' }
PCRE2PatternParser >> combineClass: left with: right operator: operator [

	operator = $& ifTrue: [ ^ [ :character | (left value: character) and: [ right value: character ] ] ].
	operator = $- ifTrue: [ ^ [ :character | (left value: character) and: [ (right value: character) not ] ] ].
	operator = $^ ifTrue: [ ^ [ :character | (left value: character) ~= (right value: character) ] ].
	^ [ :character | (left value: character) or: [ right value: character ] ]
]

{ #category : 'configuration' }
PCRE2PatternParser >> compiledOptions [

	^ compiledOptions
]

{ #category : 'parsing' }
PCRE2PatternParser >> conditionalRestoring: savedOptions [

	| condition yes no assertion reference text |
	self skipIgnored.
	(self peek = $? or: [ self peek = $* ])
		ifTrue: [
				assertion := self group.
				assertion canBeCondition ifFalse: [ self syntaxError: 'non-atomic assertion is not allowed in a conditional group' ].
				condition := [ :engine :state | assertion conditionalIn: engine state: state ] ]
		ifFalse: [
				text := self readUntil: $).
				text = 'DEFINE' ifTrue: [ condition := [ :engine :state | false ] ].
				text = 'VERSION' ifTrue: [ self unsupported: 'VERSION condition' ].
				(text beginsWith: 'R') ifTrue: [
						(text = 'R' or: [
							 (text beginsWith: 'R&') or: [ text size > 1 and: [ (text copyFrom: 2 to: text size) allSatisfy: #isDigit ] ] ]) ifTrue: [
								reference := text = 'R' ifFalse: [
										             (text beginsWith: 'R&')
											             ifTrue: [ text copyFrom: 3 to: text size ]
											             ifFalse: [ (text copyFrom: 2 to: text size) asInteger ] ].
								condition := [ :engine :state | engine isRecursing: reference state: state ] ] ].
				condition ifNil: [
						(text beginsWith: '<') ifTrue: [
								(text endsWith: '>') ifFalse: [ self syntaxError: 'missing condition delimiter' ].
								text := text copyFrom: 2 to: text size - 1 ].
						(text beginsWith: '''') ifTrue: [
								(text endsWith: '''') ifFalse: [ self syntaxError: 'missing condition delimiter' ].
								text := text copyFrom: 2 to: text size - 1 ].
						text isEmpty ifTrue: [ self syntaxError: 'empty condition' ].
						reference := self normalizedReference: text.
						references add: reference.
						condition := [ :engine :state | engine captureIsSet: reference state: state ] ] ].
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		yes := self sequence.
		no := PCRE2SequenceNode new children: #(  ).
		self peek = $| ifTrue: [
				position := position + 1.
				no := self sequence ].
		self expect: $) ] ensure: [
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
	^ PCRE2ConditionalNode new
		  definition: text = 'DEFINE';
		  dfaUnsupported: (assertion isNil and: [ text ~= 'DEFINE' and: [ text ~= 'R' ] ]);
		  condition: condition then: yes else: no
]

{ #category : 'parsing' }
PCRE2PatternParser >> controlEscape [

	| character |
	self atEnd ifTrue: [ self syntaxError: '\c at end of pattern' ].
	character := self next.
	(character asInteger between: 32 and: 126) ifFalse: [ self syntaxError: '\c must be followed by a printable ASCII character' ].
	^ self literalCodePoint: (character asUppercase asInteger bitXor: 64)
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

	| character reference delimiter start nodes property predicate code |
	character := self next.
	('dDsSwWhHvV' includes: character) ifTrue: [ ^ PCRE2CharacterNode new predicate: (self predicateFor: character) ].
	character = $C ifTrue: [
			inClass ifTrue: [ self syntaxError: 'escape sequence is invalid in character class' ].
			(options bitAnd: PCRE2 neverBackslashC) ~= 0 ifTrue: [ self syntaxError: 'using \C is disabled by the application' ].
			^ PCRE2CodeUnitNode new unicodeWideUnit: ((options bitAnd: PCRE2 utf) ~= 0 and: [ codeUnitWidth ~= 32 ]) ].
	character = $n ifTrue: [ ^ self literal: Character lf ].
	character = $r ifTrue: [
			^ self literal: ((extraOptions bitAnd: PCRE2 extraEscapedCrIsLf) = 0
					   ifTrue: [ Character cr ]
					   ifFalse: [ Character lf ]) ].
	character = $c ifTrue: [ ^ self controlEscape ].
	character = $o ifTrue: [ ^ self bracedOctalEscape ].
	(character = $U and: [ self altBSUX ]) ifTrue: [ ^ self literal: $U ].
	character = $t ifTrue: [ ^ self literal: Character tab ].
	character = $f ifTrue: [ ^ self literal: Character newPage ].
	character = $a ifTrue: [ ^ self literal: (Character value: 7) ].
	character = $e ifTrue: [ ^ self literal: (Character value: 27) ].
	(character = $u and: [ self altBSUX ]) ifTrue: [ ^ self unicodeEscape ].
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
	character = $R ifTrue: [
			inClass ifTrue: [ self syntaxError: 'invalid escape sequence in a character class' ].
			^ PCRE2NewlineNode new convention: (PCRE2NewlineConvention new mode: (bsr = PCRE2 bsrAnyCRLF
						    ifTrue: [ PCRE2 newlineAnyCRLF ]
						    ifFalse: [ PCRE2 newlineAny ])) ].
	character = $N ifTrue: [
			self peek = (Character value: 123) ifTrue: [
					(pattern findString: '{U+' startingAt: position) = position ifFalse: [
							start := position.
							reference := self quantifierBounds.
							position := start.
							reference ifNotNil: [ ^ PCRE2DotNode new convention: newlineConvention dotAll: false ] ].
					self next.
					property := (self readUntil: $}) trimBoth.
					(property beginsWith: 'U+') ifFalse: [ self syntaxError: 'only \\N{U+...} is supported' ].
					code := [ Integer readFrom: (property allButFirst: 2) readStream base: 16 ]
						        on: Error
						        do: [ :error | self syntaxError: 'invalid Unicode code point' ].
					(code > 16r10FFFF or: [ code < 0 or: [ code between: 16rD800 and: 16rDFFF ] ]) ifTrue: [
						self syntaxError: 'invalid Unicode code point' ].
					^ self literal: (Character value: code) ].
			^ PCRE2DotNode new convention: newlineConvention dotAll: false ].
	(character = $p or: [ character = $P ]) ifTrue: [
			property := self peek = (Character value: 123)
				            ifTrue: [
						            position := position + 1.
						            self readUntil: $} ]
				            ifFalse: [ self next asString ].
			predicate := [ PCRE2UnicodeData predicateFor: property caseless: (options bitAnd: PCRE2 caseless) ~= 0 ]
				             on: PCRE2UnsupportedFeature
				             do: [ :error | self syntaxError: 'unknown property after \\P or \\p' ].
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
							  options: options;
							  extraOptions: extraOptions ] ].
	character = $X ifTrue: [
			inClass ifTrue: [ self syntaxError: 'invalid escape sequence in a character class' ].
			^ PCRE2GraphemeNode new ].
	character = $E ifTrue: [ ^ PCRE2SequenceNode new children: #(  ) ].
	character = $Q ifTrue: [
			start := position.
			[ self atEnd not and: [ (self peek = $\ and: [ position < pattern size and: [ (pattern at: position + 1) = $E ] ]) not ] ]
				whileTrue: [ position := position + 1 ].
			nodes := (pattern copyFrom: start to: position - 1) collect: [ :literal | self literal: literal ] as: Array.
			self atEnd ifFalse: [ position := position + 2 ].
			^ PCRE2QuotedSequenceNode new children: nodes ].
	(character asInteger < 128 and: [ character isAlphaNumeric and: [ (extraOptions bitAnd: PCRE2 extraBadEscapeIsLiteral) = 0 ] ])
		ifTrue: [ self syntaxError: 'unrecognized character follows \' ].
	^ self literal: character
]

{ #category : 'parsing' }
PCRE2PatternParser >> expect: character [

	self next = character ifFalse: [ self syntaxError: 'expected ' , character asString ]
]

{ #category : 'callouts' }
PCRE2PatternParser >> explicitCallout [

	| number text delimiter start |
	(extraOptions bitAnd: PCRE2 extraNeverCallout) ~= 0 ifTrue: [ self syntaxError: 'callout is not allowed' ].
	number := 0.
	(self peek isNotNil and: [ self peek isDigit ]) ifTrue: [
			number := self decimal.
			number > 255 ifTrue: [ self syntaxError: 'number after (?C is greater than 255' ] ].
	(self peek isNotNil and: [ #( 39 34 96 94 37 35 36 123 ) includes: self peek asInteger ]) ifTrue: [
			delimiter := self next.
			delimiter = (Character value: 123) ifTrue: [ delimiter := $} ].
			start := position.
			text := self readCalloutStringUntil: delimiter ].
	self expect: $).
	^ self
		  newCallout: number
		  string: text
		  stringStart: start
		  position: position
]

{ #category : 'parsing' }
PCRE2PatternParser >> extendedClass [

	| predicate savedOptions |
	savedOptions := options.
	options := options bitOr: PCRE2 extended | PCRE2 extendedMore.
	[
		predicate := self classUnion.
		self classExpressionIgnored.
		self expect: $].
		self expect: $) ] ensure: [ options := savedOptions ].
	^ PCRE2CharacterNode new predicate: predicate
]

{ #category : 'parsing' }
PCRE2PatternParser >> extraMatchingBoundary: prefix [

	(extraOptions bitAnd: PCRE2 extraMatchLine) ~= 0 ifTrue: [
			^ self assertion: (prefix
					   ifTrue: [ #beginLine ]
					   ifFalse: [ #endLine ]) ].
	(extraOptions bitAnd: PCRE2 extraMatchWord) ~= 0 ifTrue: [ ^ self assertion: #wordBoundary ].
	^ nil
]

{ #category : 'configuration' }
PCRE2PatternParser >> extraOptions: flags [

	extraOptions := flags
]

{ #category : 'parsing' }
PCRE2PatternParser >> group [

	| savedOptions index name body character positive capture |
	savedOptions := {
		                options.
		                extraOptions }.
	index := nil.
	capture := (options bitAnd: PCRE2 noAutoCapture) = 0.
	self peek = $* ifTrue: [ ^ self longGroupRestoring: savedOptions ].
	self peek = $? ifTrue: [
			position := position + 1.
			character := self next.
			character = $) ifTrue: [ ^ PCRE2SequenceNode new children: #(  ) ].
			character = $* ifTrue: [
					^ PCRE2LookaheadNode new
						  child: (self groupBodyRestoring: savedOptions);
						  positive: true;
						  atomic: false ].
			character = $? ifTrue: [ self syntaxError: 'unrecognized character after (? or (?-' ].
			character = $C ifTrue: [ ^ self explicitCallout ].
			character = $[ ifTrue: [ ^ self extendedClass ].
			character = $| ifTrue: [ ^ self branchResetRestoring: savedOptions ].
			character = $( ifTrue: [ ^ self conditionalRestoring: savedOptions ].
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
					self peek = $* ifTrue: [
							self next.
							^ (self lookbehind: (self groupBodyRestoring: savedOptions) positive: true) atomic: false ].
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
								  reference: self namedBackreference;
								  options: options;
								  extraOptions: extraOptions ].
					self expect: $<.
					name := self readUntil: $> ].
			character = $R ifTrue: [
					self expect: $).
					^ PCRE2SubroutineNode new reference: 0 ].
			character = $& ifTrue: [
					name := self readUntil: $).
					references add: name.
					^ PCRE2SubroutineNode new reference: name ].
			(character between: $0 and: $9) ifTrue: [
					position := position - 1.
					index := self decimal.
					references add: index.
					self expect: $).
					^ PCRE2SubroutineNode new reference: index ].
			((character = $- or: [ character = $+ ]) and: [ self peek isNotNil and: [ self peek isDigit ] ]) ifTrue: [
					name := character asString , self decimal asString.
					index := self normalizedReference: name.
					self expect: $).
					references add: index.
					^ PCRE2SubroutineNode new reference: index ].
			name ifNil: [
					('imsxUJ-n^ar' includes: character) ifTrue: [
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
			self validateCaptureName: name.
			((names includes: name) and: [ (names at: index ifAbsent: [ nil ]) ~= name and: [ (options bitAnd: PCRE2 dupNames) = 0 ] ])
				ifTrue: [ self syntaxError: 'duplicate capture name' ].
			(names at: index ifAbsent: [ name ]) = name ifFalse: [ self syntaxError: 'different names for subpatterns of the same number' ].
			names at: index put: name ].
	body := PCRE2CaptureNode new index: index.
	groups at: index ifAbsentPut: [ body ].
	body child: (self groupBodyRestoring: savedOptions).
	^ body
]

{ #category : 'parsing' }
PCRE2PatternParser >> groupBodyRestoring: savedOptions [

	| body |
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		body := self alternation.
		self expect: $) ] ensure: [
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
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

	| digits start |
	(self atEnd and: [ self altBSUX not ]) ifTrue: [ self syntaxError: '\x is not followed by a hexadecimal digit' ].
	self altBSUX ifTrue: [
			start := position.
			digits := String streamContents: [ :stream |
				          2 timesRepeat: [
					          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ].
			digits size = 2 ifFalse: [
					position := start.
					^ self literal: $x ].
			^ self literalCodePoint: (Integer readFrom: digits readStream base: 16) ].
	self peek = (Character value: 123)
		ifTrue: [
				self next.
				digits := (self readUntil: $}) trimBoth.
				(digits isEmpty or: [ digits anySatisfy: [ :character | (character digitValue between: 0 and: 15) not ] ]) ifTrue: [
					self syntaxError: 'non-hex character in \\x{} (closing brace missing?)' ] ]
		ifFalse: [
				digits := String streamContents: [ :stream |
					          2 timesRepeat: [
						          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ].
				digits isEmpty ifTrue: [ self syntaxError: 'hexadecimal digit expected' ] ].
	^ self literalCodePoint: (Integer readFrom: digits readStream base: 16)
]

{ #category : 'callouts' }
PCRE2PatternParser >> initializePatternOffsets [

	| offset code width |
	offset := 0.
	patternOffsets := Array new: pattern size + 1.
	patternOffsets at: 1 put: 0.
	pattern withIndexDo: [ :character :index |
			code := character asInteger.
			width := (options bitAnd: PCRE2 utf) = 0
				         ifTrue: [ 1 ]
				         ifFalse: [
						         codeUnitWidth = 32
							         ifTrue: [ 1 ]
							         ifFalse: [
									         codeUnitWidth = 16
										         ifTrue: [
												         code > 65535
													         ifTrue: [ 2 ]
													         ifFalse: [ 1 ] ]
										         ifFalse: [
												         code < 128
													         ifTrue: [ 1 ]
													         ifFalse: [
															         code < 2048
																         ifTrue: [ 2 ]
																         ifFalse: [
																		         code < 65536
																			         ifTrue: [ 3 ]
																			         ifFalse: [ 4 ] ] ] ] ] ].
			offset := offset + width.
			patternOffsets at: index + 1 put: offset ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> inlineOptions [

	| remove flags character flag seenX extra hyphenAllowed |
	hyphenAllowed := true.
	self peek = $^ ifTrue: [
			self next.
			hyphenAllowed := false.
			extraOptions := extraOptions bitAnd: PCRE2 extraCaselessRestrict bitInvert.
			options := options bitAnd:
				           (PCRE2 caseless | PCRE2 multiline | PCRE2 dotAll | PCRE2 noAutoCapture | PCRE2 extended | PCRE2 extendedMore)
					           bitInvert ].
	remove := false.
	seenX := 0.
	flags := Dictionary newFrom: {
			         ($i -> PCRE2 caseless).
			         ($m -> PCRE2 multiline).
			         ($s -> PCRE2 dotAll).
			         ($x -> PCRE2 extended).
			         ($U -> PCRE2 ungreedy).
			         ($n -> PCRE2 noAutoCapture).
			         ($J -> PCRE2 dupNames) }.
	[ self atEnd not and: [ self peek ~= $: and: [ self peek ~= $) ] ] ] whileTrue: [
			character := self next.
			character = $-
				ifTrue: [
						hyphenAllowed ifFalse: [ self syntaxError: 'invalid hyphen in option setting' ].
						hyphenAllowed := false.
						remove := true ]
				ifFalse: [
						extra := character = $a or: [ character = $r ].
						flag := character = $a
							        ifTrue: [ self asciiInlineOption ]
							        ifFalse: [
									        character = $r
										        ifTrue: [ PCRE2 extraCaselessRestrict ]
										        ifFalse: [ flags at: character ifAbsent: [ self syntaxError: 'unrecognized character after (? or (?-' ] ] ].
						character = $x ifTrue: [
								seenX := seenX + 1.
								(remove not and: [ seenX = 1 ]) ifTrue: [ options := options bitAnd: PCRE2 extendedMore bitInvert ].
								(remove or: [ seenX > 1 ]) ifTrue: [ flag := flag bitOr: PCRE2 extendedMore ] ].
						extra
							ifTrue: [
									extraOptions := remove
										                ifTrue: [ extraOptions bitAnd: flag bitInvert ]
										                ifFalse: [ extraOptions bitOr: flag ] ]
							ifFalse: [
									options := remove
										           ifTrue: [ options bitAnd: flag bitInvert ]
										           ifFalse: [ options bitOr: flag ] ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> literal: character [

	| caseless unicode caseOptions |
	caseless := (options bitAnd: PCRE2 caseless) ~= 0.
	caseOptions := extraOptions.
	unicode := (options bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0.
	^ PCRE2CharacterNode new
		  character: character;
		  predicate: [ :candidate |
				  candidate = character or: [
							  caseless and: [
										  PCRE2UnicodeData
											  same: candidate
											  as: character
											  unicode: unicode
											  extraOptions: caseOptions ] ] ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> literalCodePoint: code [

	| maximum |
	maximum := (options bitAnd: PCRE2 utf) ~= 0
		           ifTrue: [ 16r10FFFF ]
		           ifFalse: [
				           codeUnitWidth = 8
					           ifTrue: [ 255 ]
					           ifFalse: [
							           codeUnitWidth = 16
								           ifTrue: [ 65535 ]
								           ifFalse: [ 16rFFFFFFFF ] ] ].
	code > maximum ifTrue: [ self syntaxError: 'character code point too large' ].
	((options bitAnd: PCRE2 utf) ~= 0 and: [
		 (code between: 16rD800 and: 16rDFFF) and: [ (extraOptions bitAnd: PCRE2 extraAllowSurrogateEscapes) = 0 ] ]) ifTrue: [
		self syntaxError: 'disallowed Unicode code point (>= 0xd800 && <= 0xdfff)' ].
	^ self literal: (PCRE2CodeUnit fromInteger: code)
]

{ #category : 'parsing' }
PCRE2PatternParser >> longGroupRestoring: savedOptions [

	| name argument kinds child |
	self expect: $*.
	name := String streamContents: [ :stream |
		        [ self atEnd not and: [ self peek ~= $: and: [ self peek ~= $) ] ] ] whileTrue: [ stream nextPut: self next ] ].
	(#( 'napla' 'non_atomic_positive_lookahead' ) includes: name) ifTrue: [
			self expect: $:.
			^ PCRE2LookaheadNode new
				  child: (self groupBodyRestoring: savedOptions);
				  positive: true;
				  atomic: false ].
	(#( 'naplb' 'non_atomic_positive_lookbehind' ) includes: name) ifTrue: [
			self expect: $:.
			^ (self lookbehind: (self groupBodyRestoring: savedOptions) positive: true) atomic: false ].
	(#( 'pla' 'positive_lookahead' 'nla' 'negative_lookahead' ) includes: name) ifTrue: [
			self expect: $:.
			^ PCRE2LookaheadNode new
				  child: (self groupBodyRestoring: savedOptions);
				  positive: (#( 'pla' 'positive_lookahead' ) includes: name) ].
	(#( 'plb' 'positive_lookbehind' 'nlb' 'negative_lookbehind' ) includes: name) ifTrue: [
			self expect: $:.
			^ self lookbehind: (self groupBodyRestoring: savedOptions) positive: (#( 'plb' 'positive_lookbehind' ) includes: name) ].
	(#( 'sr' 'script_run' 'asr' 'atomic_script_run' ) includes: name) ifTrue: [
			self expect: $:.
			child := self groupBodyRestoring: savedOptions.
			(#( 'asr' 'atomic_script_run' ) includes: name) ifTrue: [ child := PCRE2AtomicNode new child: child ].
			^ PCRE2ScriptRunNode new child: child ].
	name = 'atomic' ifTrue: [
			self expect: $:.
			^ PCRE2AtomicNode new child: (self groupBodyRestoring: savedOptions) ].
	self peek = $:
		ifTrue: [
				self next.
				argument := self readUntil: $) ]
		ifFalse: [ self expect: $) ].
	kinds := Dictionary newFrom: {
			         ('MARK' -> #mark).
			         ('' -> #mark).
			         ('FAIL' -> #fail).
			         ('F' -> #fail).
			         ('ACCEPT' -> #accept).
			         ('COMMIT' -> #commit).
			         ('PRUNE' -> #prune).
			         ('SKIP' -> #skip).
			         ('THEN' -> #then) }.
	(kinds includesKey: name) ifFalse: [ self unsupported: 'backtracking control verb ' , name ].
	((kinds at: name) = #mark and: [ argument isEmptyOrNil ]) ifTrue: [ self syntaxError: 'MARK requires an argument' ].
	argument isEmptyOrNil ifTrue: [ argument := nil ].
	^ PCRE2ControlNode new kind: (kinds at: name) name: argument
]

{ #category : 'parsing' }
PCRE2PatternParser >> lookbehind: body positive: positive [

	| node |
	node := PCRE2LookbehindNode new
		        branches: body lookbehindBranches;
		        positive: positive.
	lookbehinds add: {
			node.
			body lookbehindBranches }.
	^ node
]

{ #category : 'configuration' }
PCRE2PatternParser >> lookbehindLimit: anInteger [

	lookbehindLimit := anInteger
]

{ #category : 'accessing' }
PCRE2PatternParser >> maximumLookbehind [

	| maximum |
	maximum := requiresPreviousCharacter = true
		           ifTrue: [ 1 ]
		           ifFalse: [ 0 ].
	lookbehinds do: [ :entry | entry second do: [ :branch | maximum := maximum max: (entry first maximumLengthFor: branch) ] ].
	^ maximum
]

{ #category : 'parsing' }
PCRE2PatternParser >> namedBackreference [

	| name |
	name := self readUntil: $).
	references add: name.
	^ name
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

{ #category : 'callouts' }
PCRE2PatternParser >> newCallout: number string: text stringStart: textStart position: index [

	| site offset |
	offset := self codeUnitOffsetAt: index.
	site := PCRE2CalloutSite new
		        number: number
		        position: offset
		        nextLength: 0
		        string: text
		        offset: (textStart ifNil: [ 0 ] ifNotNil: [ self codeUnitOffsetAt: textStart ])
		        length: (text ifNil: [ 0 ] ifNotNil: [ self calloutStringSize: text ]).
	calloutSites add: site.
	^ PCRE2CalloutNode new site: site
]

{ #category : 'configuration' }
PCRE2PatternParser >> newline: mode bsr: bsrMode [

	newlineConvention := PCRE2NewlineConvention new mode: mode.
	bsr := bsrMode
]

{ #category : 'configuration' }
PCRE2PatternParser >> newlineMode [

	^ newlineConvention mode
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
	((extraOptions bitAnd: PCRE2 extraPythonOctal) ~= 0
		 ifTrue: [
		 (position - saved >= 3 and: [ (pattern copyFrom: saved to: saved + 2) allSatisfy: [ :digit | digit between: $0 and: $7 ] ]) not ]
		 ifFalse: [ reference < 10 or: [ (pattern at: saved) >= $8 or: [ reference <= captureCount ] ] ]) ifTrue: [
			references add: reference.
			^ PCRE2BackreferenceNode new
				  reference: reference;
				  options: options;
				  extraOptions: extraOptions ].
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
	count = 0 ifTrue: [ ^ self literal: self next ].
	((extraOptions bitAnd: PCRE2 extraPythonOctal) ~= 0 and: [ value > 255 ]) ifTrue: [
		self syntaxError: 'octal value is greater than 377 in Python octal mode' ].
	((extraOptions bitAnd: PCRE2 extraNoBs0) ~= 0 and: [ value = 0 and: [ count = 1 ] ]) ifTrue: [
		self syntaxError: '\0 is not allowed' ].
	^ self literalCodePoint: value
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
	self validateLookbehinds.
	calloutSites do: [ :site | site nextItemLength: (itemLengths at: site patternPosition ifAbsent: [ 0 ]) ].
	^ result
]

{ #category : 'parsing' }
PCRE2PatternParser >> parse: preparedInput options: compileOptions [

	| prefix tree |
	newlineConvention ifNil: [ self newline: PCRE2 newlineLF bsr: PCRE2 bsrUnicode ].
	extraOptions ifNil: [ extraOptions := 0 ].
	input := preparedInput.
	pattern := (compileOptions bitAnd: PCRE2 utf) = 0
		           ifTrue: [ PCRE2CodeUnitText from: input bytes width: codeUnitWidth ]
		           ifFalse: [ self utfPattern ].
	options := compileOptions.
	position := 1.
	self startDirectives.
	compiledOptions := options.
	(options bitAnd: PCRE2 utf) ~= 0 ifTrue: [
			pattern := self utfPattern.
			pattern isString ifFalse: [ pattern := pattern asString ] ].
	self initializePatternOffsets.
	self validateTurkishCasing.
	((options bitAnd: PCRE2 neverUTF) ~= 0 and: [ (options bitAnd: PCRE2 utf) ~= 0 ]) ifTrue: [
		self syntaxError: 'using UTF is disabled by the application' ].
	((options bitAnd: PCRE2 neverUCP) ~= 0 and: [ (options bitAnd: PCRE2 ucp) ~= 0 ]) ifTrue: [
		self syntaxError: 'using UCP is disabled by the application' ].
	captureCount := 0.
	names := Dictionary new.
	groups := Dictionary new.
	depth := 0.
	nestLimit ifNil: [ nestLimit := 250 ].
	lookbehindLimit ifNil: [ lookbehindLimit := 255 ].
	calloutSites := OrderedCollection new.
	itemLengths := Dictionary new.
	references := OrderedCollection new.
	lookbehinds := OrderedCollection new.
	prefix := self extraMatchingBoundary: true.
	tree := (options bitAnd: PCRE2 literal) ~= 0
		        ifTrue: [ PCRE2SequenceNode new children: (pattern collect: [ :character | self literal: character ] as: Array) ]
		        ifFalse: [ self parse ].
	^ prefix ifNil: [ tree ] ifNotNil: [
			  PCRE2SequenceNode new children: {
					  prefix.
					  tree.
					  (self extraMatchingBoundary: false) } ]
]

{ #category : 'configuration' }
PCRE2PatternParser >> patternLimits [

	^ patternLimits
]

{ #category : 'configuration' }
PCRE2PatternParser >> patternMatchOptions [

	^ patternMatchOptions
]

{ #category : 'parsing' }
PCRE2PatternParser >> peek [

	^ self atEnd ifFalse: [ pattern at: position ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> piece [

	| start node |
	start := position.
	node := self quantifiedAtom.
	itemLengths at: (self codeUnitOffsetAt: start) put: (self codeUnitOffsetAt: position) - (self codeUnitOffsetAt: start).
	^ node
]

{ #category : 'parsing' }
PCRE2PatternParser >> predicateFor: character [

	| predicate unicode kind |
	unicode := (options bitAnd: PCRE2 ucp) ~= 0.
	kind := character asLowercase.
	((kind = $d and: [ (extraOptions bitAnd: PCRE2 extraAsciiBsd) ~= 0 ]) or: [
			 (kind = $s and: [ (extraOptions bitAnd: PCRE2 extraAsciiBss) ~= 0 ]) or: [
				 kind = $w and: [ (extraOptions bitAnd: PCRE2 extraAsciiBsw) ~= 0 ] ] ]) ifTrue: [ unicode := false ].
	kind = $d ifTrue: [
			predicate := unicode
				             ifTrue: [ [ :candidate | PCRE2UnicodeData matches: 'gc:nd' code: candidate asInteger ] ]
				             ifFalse: [ [ :candidate | candidate between: $0 and: $9 ] ] ].
	kind = $w ifTrue: [
			predicate := unicode
				             ifTrue: [ [ :candidate | PCRE2UnicodeData isWord: candidate asInteger ] ]
				             ifFalse: [
						             [ :candidate |
							             (candidate between: $a and: $z) or: [
								             (candidate between: $A and: $Z) or: [ (candidate between: $0 and: $9) or: [ candidate = $_ ] ] ] ] ] ].
	kind = $s ifTrue: [
			predicate := unicode
				             ifTrue: [ [ :candidate | PCRE2UnicodeData isSpace: candidate asInteger ] ]
				             ifFalse: [ [ :candidate | #( 9 10 11 12 13 32 ) includes: candidate asInteger ] ] ].
	kind = $h ifTrue: [
			predicate := [ :candidate |
			             #( 9 32 160 5760 6158 8192 8193 8194 8195 8196 8197 8198 8199 8200 8201 8202 8239 8287 12288 ) includes:
				             candidate asInteger ] ].
	kind = $v ifTrue: [ predicate := [ :candidate | #( 10 11 12 13 133 8232 8233 ) includes: candidate asInteger ] ].
	character isUppercase ifTrue: [ ^ [ :candidate | (predicate value: candidate) not ] ].
	^ predicate
]

{ #category : 'parsing' }
PCRE2PatternParser >> propertyPredicate: property [

	| unicode name |
	unicode := (options bitAnd: PCRE2 ucp) ~= 0.
	name := property first = $^
		        ifTrue: [ property allButFirst ]
		        ifFalse: [ property ].
	((extraOptions bitAnd: PCRE2 extraAsciiPosix) ~= 0 or: [
		 (extraOptions bitAnd: PCRE2 extraAsciiDigit) ~= 0 and: [ #( 'digit' 'xdigit' ) includes: name ] ]) ifTrue: [ unicode := false ].
	^ PCRE2UnicodeData posixPredicate: property unicode: unicode caseless: (options bitAnd: PCRE2 caseless) ~= 0
]

{ #category : 'parsing' }
PCRE2PatternParser >> quantifiedAtom [

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

	| unicode caseOptions |
	caseOptions := extraOptions.
	unicode := (options bitAnd: PCRE2 utf | PCRE2 ucp) ~= 0.
	^ [ :candidate |
		  (candidate between: low and: high) or: [
				  caseless and: [
						  PCRE2UnicodeData
							  inRange: candidate asInteger
							  from: low asInteger
							  to: high asInteger
							  unicode: unicode
							  extraOptions: caseOptions ] ] ]
]

{ #category : 'callouts' }
PCRE2PatternParser >> readCalloutStringUntil: delimiter [

	| stream character |
	stream := WriteStream on: String new.
	[ self atEnd not ] whileTrue: [
			character := self next.
			character = delimiter ifTrue: [
					self peek = delimiter ifFalse: [ ^ stream contents ].
					self next ].
			stream nextPut: character ].
	self syntaxError: 'missing terminating delimiter for callout string'
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
			((options bitAnd: PCRE2 autoCallout) ~= 0 and: [ (pattern findString: '(?C' startingAt: position) ~= position ]) ifTrue: [
					nodes add: (self
							 newCallout: PCRE2 automaticCalloutNumber
							 string: nil
							 stringStart: nil
							 position: position) ].
			nodes add: self piece.
			self skipIgnored ].
	(options bitAnd: PCRE2 autoCallout) ~= 0 ifTrue: [
			itemLengths at: (self codeUnitOffsetAt: position) put: (self atEnd
					 ifTrue: [ 0 ]
					 ifFalse: [ 1 ]).
			nodes add: (self
					 newCallout: PCRE2 automaticCalloutNumber
					 string: nil
					 stringStart: nil
					 position: position) ].
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
		(extended and: [ self atEnd not and: [ (#( 9 10 11 12 13 32 ) includes: self peek asInteger) or: [ self peek = $# ] ] ])
			ifTrue: [
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

{ #category : 'configuration' }
PCRE2PatternParser >> startDirectives [

	| end directive newlineNames optionNames extraNames matchNames limitNames key value |
	patternMatchOptions := 0.
	patternLimits := Dictionary new.
	(options bitAnd: PCRE2 literal) ~= 0 ifTrue: [ ^ self ].
	newlineNames := Dictionary newFrom: {
			                ('CR' -> PCRE2 newlineCR).
			                ('LF' -> PCRE2 newlineLF).
			                ('CRLF' -> PCRE2 newlineCRLF).
			                ('ANY' -> PCRE2 newlineAny).
			                ('ANYCRLF' -> PCRE2 newlineAnyCRLF).
			                ('NUL' -> PCRE2 newlineNul) }.
	optionNames := Dictionary newFrom: {
			               ('UTF' -> PCRE2 utf).
			               ('UTF' , codeUnitWidth asString -> PCRE2 utf).
			               ('UCP' -> PCRE2 ucp).
			               ('NO_AUTO_POSSESS' -> PCRE2 noAutoPossess).
			               ('NO_START_OPT' -> PCRE2 noStartOptimize).
			               ('NO_DOTSTAR_ANCHOR' -> PCRE2 noDotstarAnchor).
			               ('NO_JIT' -> 0) }.
	extraNames := Dictionary newFrom: {
			              ('CASELESS_RESTRICT' -> PCRE2 extraCaselessRestrict).
			              ('TURKISH_CASING' -> PCRE2 extraTurkishCasing) }.
	matchNames := Dictionary newFrom: {
			              ('NOTEMPTY' -> PCRE2 notEmpty).
			              ('NOTEMPTY_ATSTART' -> PCRE2 notEmptyAtStart) }.
	limitNames := Dictionary newFrom: {
			              ('LIMIT_MATCH' -> #match).
			              ('LIMIT_DEPTH' -> #depth).
			              ('LIMIT_RECURSION' -> #depth).
			              ('LIMIT_HEAP' -> #heap) }.
	[ (pattern findString: '(*' startingAt: position) = position ] whileTrue: [
			end := pattern indexOf: $) startingAt: position + 2 ifAbsent: [ ^ self ].
			directive := pattern copyFrom: position + 2 to: end - 1.
			(newlineNames includesKey: directive)
				ifTrue: [ newlineConvention := PCRE2NewlineConvention new mode: (newlineNames at: directive) ]
				ifFalse: [
						(optionNames includesKey: directive)
							ifTrue: [ options := options bitOr: (optionNames at: directive) ]
							ifFalse: [
									(extraNames includesKey: directive)
										ifTrue: [ extraOptions := extraOptions bitOr: (extraNames at: directive) ]
										ifFalse: [
												(matchNames includesKey: directive)
													ifTrue: [ patternMatchOptions := patternMatchOptions bitOr: (matchNames at: directive) ]
													ifFalse: [
															directive = 'BSR_ANYCRLF'
																ifTrue: [ bsr := PCRE2 bsrAnyCRLF ]
																ifFalse: [
																		directive = 'BSR_UNICODE'
																			ifTrue: [ bsr := PCRE2 bsrUnicode ]
																			ifFalse: [
																					key := directive copyUpTo: $=.
																					(limitNames includesKey: key) ifFalse: [ ^ self ].
																					value := directive copyAfter: $=.
																					(value isEmpty or: [ (value allSatisfy: [ :digit | digit between: $0 and: $9 ]) not ]) ifTrue: [ ^ self ].
																					value := value asInteger.
																					value > 16rFFFFFFFF ifTrue: [ ^ self ].
																					patternLimits at: (limitNames at: key) put: value ] ] ] ] ] ].
			position := end + 1 ].
	compiledOptions := options
]

{ #category : 'parsing' }
PCRE2PatternParser >> syntaxError: message [

	| offset |
	offset := patternOffsets at: (position min: pattern size + 1).
	PCRE2CompileError signal: message in: input at: offset
]

{ #category : 'parsing' }
PCRE2PatternParser >> unicodeEscape [

	| digits start code |
	start := position.
	(self peek = (Character value: 123) and: [ (extraOptions bitAnd: PCRE2 extraAltBsux) ~= 0 ])
		ifTrue: [
				self next.
				digits := self readUntil: $} ]
		ifFalse: [
				digits := String streamContents: [ :stream |
					          4 timesRepeat: [
						          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ].
				digits size < 4 ifTrue: [
						position := start.
						^ self literal: $u ] ].
	digits isEmpty ifTrue: [ self syntaxError: 'hexadecimal digit expected' ].
	code := [ Integer readFrom: digits readStream base: 16 ]
		        on: Error
		        do: [ :error | self syntaxError: 'hexadecimal digit expected' ].
	code > 16r10FFFF ifTrue: [ self syntaxError: 'character code point too large' ].
	^ self literalCodePoint: code
]

{ #category : 'parsing' }
PCRE2PatternParser >> unsupported: feature [

	PCRE2UnsupportedFeature signal: 'Pharo backend does not yet support ' , feature
]

{ #category : 'parsing' }
PCRE2PatternParser >> utfPattern [

	(PCRE2CodeUnitText utfErrorIn: input bytes width: codeUnitWidth) ifNotNil: [ :error |
		PCRE2CompileError signal: (PCRE2 translateErrorCode: error first) in: input at: error second ].
	^ (input readFrom: 1 to: input size) asString
]

{ #category : 'parsing' }
PCRE2PatternParser >> validateCaptureName: name [

	| unicode first |
	name isEmpty ifTrue: [ self syntaxError: 'empty capture name' ].
	unicode := (options bitAnd: PCRE2 utf) ~= 0.
	first := name first.
	(first = $_ or: [
			 unicode
				 ifTrue: [ PCRE2UnicodeData matches: 'gc:l' code: first asInteger ]
				 ifFalse: [ (first between: $A and: $Z) or: [ first between: $a and: $z ] ] ]) ifFalse: [
		self syntaxError: 'subpattern name must start with a non-digit' ].
	(name allSatisfy: [ :character |
			 character = $_ or: [
					 unicode
						 ifTrue: [
							 (PCRE2UnicodeData matches: 'gc:l' code: character asInteger) or: [
								 PCRE2UnicodeData matches: 'gc:nd' code: character asInteger ] ]
						 ifFalse: [ character asInteger < 128 and: [ character isAlphaNumeric ] ] ] ]) ifFalse: [
		self syntaxError: 'syntax error in subpattern name' ].
	(codeUnitWidth = 8
		 ifTrue: [ name asPCRE2UTF8Input size ]
		 ifFalse: [
				 codeUnitWidth = 16
					 ifTrue: [ name asPCRE2UTF16Input size ]
					 ifFalse: [ name size ] ]) > 128 ifTrue: [ self syntaxError: 'subpattern name is too long' ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> validateLookbehinds [

	lookbehinds do: [ :entry |
			| bounds |
			bounds := IdentityDictionary new.
			entry second do: [ :branch |
					| lengths |
					lengths := branch lengthBoundsUsing: groups names: names visited: IdentitySet new.
					lengths second ifNil: [ self syntaxError: 'length of lookbehind assertion is not limited' ].
					(lengths second > lookbehindLimit and: [ lengths first ~= lengths second ]) ifTrue: [
						self syntaxError: 'lookbehind is too long' ].
					bounds at: branch put: lengths ].
			entry first branchBounds: bounds ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> validateTurkishCasing [

	(extraOptions bitAnd: PCRE2 extraTurkishCasing) = 0 ifTrue: [ ^ self ].
	(options bitAnd: PCRE2 utf | PCRE2 ucp) = 0 ifTrue: [ self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING requires UTF or UCP' ].
	(codeUnitWidth = 8 and: [ (options bitAnd: PCRE2 utf) = 0 ]) ifTrue: [
		self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING requires UTF in 8-bit mode' ].
	(extraOptions bitAnd: PCRE2 extraCaselessRestrict) ~= 0 ifTrue: [
		self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING is incompatible with PCRE2_EXTRA_CASELESS_RESTRICT' ]
]
