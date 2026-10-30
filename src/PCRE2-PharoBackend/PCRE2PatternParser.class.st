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
		'requiresPreviousCharacter',
		'branchResetUsed',
		'extendedClassDepth',
		'referenceOffsets',
		'lookbehindPositions',
		'classExpressionDelimiter',
		'classExpressionStart',
		'utsNestedClassClosed',
		'backreferences',
		'hadPruneOrSkip',
		'startLine'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'configuration' }
PCRE2PatternParser class >> limitDirectives [
	"The start directives that carry a value, mapped to the limit each one sets."

	^ Dictionary newFrom: {
			  ('LIMIT_MATCH' -> #match).
			  ('LIMIT_DEPTH' -> #depth).
			  ('LIMIT_RECURSION' -> #depth).
			  ('LIMIT_HEAP' -> #heap) }
]

{ #category : 'parsing - escapes' }
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

{ #category : 'parsing - optimization' }
PCRE2PatternParser >> analyseStartOf: tree [
	"PCRE2's two structural start optimizations, decided once the whole tree stands. A pattern every branch of which starts at a fixed place is anchored, whatever else is turned off; one every branch of which starts at a line start is only ever tried there, which is of no use to a pattern that is anchored already or that has a first character to look for."

	| analysis |
	startLine := false.
	((compiledOptions bitOr: patternMatchOptions) bitAnd: PCRE2 anchored) ~= 0 ifTrue: [ ^ self ].
	analysis := PCRE2StartAnalysis
		            backreferences: self backreferenceMap
		            pruneOrSkip: hadPruneOrSkip
		            dotStarAnchor: (compiledOptions bitAnd: PCRE2 noDotstarAnchor) = 0.
	(tree isAnchoredIn: analysis) ifTrue: [
			compiledOptions := compiledOptions bitOr: PCRE2 anchored.
			^ self ].
	(compiledOptions bitAnd: PCRE2 noStartOptimize) ~= 0 ifTrue: [ ^ self ].
	tree firstLiteralPredicate ifNotNil: [ ^ self ].
	startLine := tree isStartLineIn: analysis
]

{ #category : 'parsing - groups' }
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
	"The node for one zero-width position assertion. Its predicate is chosen here, once, so matching never asks again which kind it is."

	(#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [ requiresPreviousCharacter := true ].
	^ PCRE2AssertionNode new
		  kind: kind;
		  multiline: (options bitAnd: PCRE2 multiline) ~= 0;
		  byteTest: (self byteTestFor: kind);
		  predicate: (self assertionPredicateFor: kind)
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> assertionPredicateFor: kind [
	"The block that decides one assertion kind while matching."

	kind = #beginSubject ifTrue: [ ^ [ :engine :state | state position = 0 ] ].
	kind = #endSubject ifTrue: [ ^ self endOfSubjectPredicate ].
	kind = #beginLine ifTrue: [ ^ self startOfLinePredicate ].
	kind = #endLine ifTrue: [ ^ self endOfLinePredicate ].
	kind = #endBeforeFinalNewline ifTrue: [ ^ self endBeforeFinalNewlinePredicate ].
	kind = #startMatch ifTrue: [ ^ [ :engine :state | state position = engine initialPosition ] ].
	kind = #resetStart ifTrue: [
			^ [ :engine :state |
				  state captures at: 1 put: state position.
				  true ] ].
	^ self wordBoundaryPredicateFor: kind
]

{ #category : 'scanning' }
PCRE2PatternParser >> atEnd [

	^ position > pattern size
]

{ #category : 'parsing' }
PCRE2PatternParser >> atom [

	| character saved bounds |
	character := self next.
	character = $( ifTrue: [ ^ self group ].
	character = $[ ifTrue: [ ^ self characterClass ].
	character = $\ ifTrue: [ ^ self escapeInClass: false ].
	character = $. ifTrue: [ ^ PCRE2DotNode new convention: newlineConvention dotAll: (options bitAnd: PCRE2 dotAll) ~= 0 ].
	character = $^ ifTrue: [ ^ self assertion: #beginLine ].
	character = $$ ifTrue: [ ^ self assertion: #endLine ].
	character = (Character value: 123) ifTrue: [
			saved := position.
			position := position - 1.
			bounds := self quantifierBounds.
			bounds ifNotNil: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
			position := saved ].
	('*+?' includes: character) ifTrue: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
	^ self literal: character
]

{ #category : 'parsing - optimization' }
PCRE2PatternParser >> backreferenceMap [
	"The groups backreferences point at, in PCRE2's bitmap of the first 31 of them."

	| map |
	map := 0.
	backreferences do: [ :reference |
			reference isInteger
				ifTrue: [ map := map bitOr: (PCRE2StartAnalysis bitFor: reference) ]
				ifFalse: [
				names keysAndValuesDo: [ :index :name | name = reference ifTrue: [ map := map bitOr: (PCRE2StartAnalysis bitFor: index) ] ] ] ].
	^ map
]

{ #category : 'scanning' }
PCRE2PatternParser >> bracedNumberInBase: base invalidCode: errorCode [

	| start digits |
	[ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ].
	start := position.
	[ self peek isNotNil and: [ self peek asInteger < 128 and: [ self peek digitValue between: 0 and: base - 1 ] ] ] whileTrue: [
		self next ].
	digits := pattern copyFrom: start to: position - 1.
	[ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ].
	self peek = $} ifFalse: [
			self atEnd
				ifTrue: [ digits ifEmpty: [ self syntaxErrorCode: 178 ] ]
				ifFalse: [ self next ].
			self syntaxErrorCode: errorCode ].
	digits ifEmpty: [ self syntaxErrorCode: 178 ].
	self next.
	^ Integer readFrom: digits readStream base: base
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> bracedOctalEscape [

	self peek = (Character value: 123) ifFalse: [ self syntaxErrorCode: 155 ].
	self next.
	^ self literalCodePoint: (self bracedNumberInBase: 8 invalidCode: 164)
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> branchResetRestoring: savedOptions [

	| base maximum alternatives |
	branchResetUsed := true.
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
		self expect: $) errorCode: 114 ] ensure: [
			captureCount := maximum.
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
	^ PCRE2AlternativeNode new children: alternatives asArray
]

{ #category : 'accessing' }
PCRE2PatternParser >> bsrMode [

	^ bsr
]

{ #category : 'parsing' }
PCRE2PatternParser >> byteConditionFor: callouts constant: constantFalse numbered: aNumber version: aVersion [
	"What a written matcher can ask of a conditional's condition, or nil when it cannot ask it. A condition already settled while the pattern was read leaves one branch, and a group number is one offset to look at; a recursion, a name shared by several groups, and a lookaround condition are all answered from how the match is going."

	callouts ifNotEmpty: [ ^ nil ].
	constantFalse ifTrue: [ ^ #( #never ) ].
	aVersion ifNotNil: [ ^ #( #always ) ].
	aNumber ifNil: [ ^ nil ].
	^ {
		  #groupSet.
		  aNumber }
]

{ #category : 'parsing' }
PCRE2PatternParser >> byteTestFor: kind [
	"How a written matcher can decide this assertion by reading bytes, or nil when it cannot. The options that change what an assertion means are read here, where they are known, rather than carried into the generator."

	| terminator multiline |
	kind = #beginSubject ifTrue: [ ^ #( #atStart ) ].
	kind = #endSubject ifTrue: [ ^ #( #atEnd ) ].
	(#( wordBoundary notWordBoundary ) includes: kind) ifTrue: [
			^ {
				  #wordBoundary.
				  (kind = #wordBoundary).
				  (PCRE2CharacterNode tableFor: (self predicateFor: $w)) } ].
	multiline := (options bitAnd: PCRE2 multiline) ~= 0.
	(kind = #beginLine and: [ multiline not ]) ifTrue: [ ^ #( #atStart ) ].
	(kind = #endLine and: [ multiline not and: [ (options bitAnd: PCRE2 dollarEndOnly) ~= 0 ] ]) ifTrue: [ ^ #( #atEnd ) ].
	terminator := self singleNewlineCode ifNil: [ ^ nil ].
	kind = #beginLine ifTrue: [
			^ {
				  #afterTerminator.
				  terminator.
				  ((options bitAnd: PCRE2 altCircumflex) ~= 0) } ].
	kind = #endBeforeFinalNewline ifTrue: [
			^ {
				  #beforeFinalTerminator.
				  terminator } ].
	kind = #endLine ifTrue: [
			^ multiline
				  ifTrue: [
						  {
							  #beforeTerminator.
							  terminator } ]
				  ifFalse: [
						  {
							  #beforeFinalTerminator.
							  terminator } ] ].
	^ nil
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

{ #category : 'accessing' }
PCRE2PatternParser >> captureCount [

	^ captureCount
]

{ #category : 'accessing' }
PCRE2PatternParser >> captureCount: anInteger [

	captureCount := anInteger
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> captureReferenceList [

	| result reference start delimiter |
	result := OrderedCollection new.
	self peek = $( ifFalse: [ self syntaxErrorCode: 218 ].
	self next.
	[
		start := position.
		reference := self readReferenceNumber.
		reference ifNil: [
				(self peek = $< or: [ self peek = $' ]) ifFalse: [ self syntaxErrorCode: 217 ].
				delimiter := self next = $<
					             ifTrue: [ $> ]
					             ifFalse: [ $' ].
				start := position.
				reference := self readCaptureNameUntil: delimiter ].
		(reference isInteger and: [ reference = 0 ]) ifTrue: [ self syntaxErrorCode: 115 ].
		self registerReference: reference at: start.
		result add: reference.
		self atEnd ifTrue: [ self syntaxErrorCode: 114 ].
		self peek = $) ifTrue: [
				self next.
				^ result asArray ].
		self peek = $, ifFalse: [ self syntaxErrorCode: 124 ].
		self next ] repeat
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> characterClass [

	(options bitAnd: PCRE2 altExtendedClass) ~= 0 ifTrue: [ ^ self utsClass ].
	^ (extendedClassDepth ifNil: [ 0 ]) > 0
		  ifTrue: [ self withExtendedClassDo: [ self parseCharacterClass ] ]
		  ifFalse: [ self parseCharacterClass ]
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> classElement [

	^ self classElementAsRangeEnd: false
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> classElementAsRangeEnd: isRangeEnd [
	"PCRE2 blames a POSIX collating element differently when it closes a range."

	| character property closing nested |
	character := self next.
	character = $\ ifTrue: [ ^ self escapeInClass: true ].
	(character = $[ and: [ self peek isNotNil and: [ '.=' includes: self peek ] ]) ifTrue: [
			closing := pattern findString: (String with: self peek with: $]) startingAt: position + 1.
			closing > 0 ifTrue: [
					self
						syntaxErrorCode: (isRangeEnd
								 ifTrue: [ 150 ]
								 ifFalse: [ 113 ])
						atCodeUnit: (self codeUnitOffsetAt: closing + 2) ] ].
	(character = $[ and: [ self peek = $: ]) ifTrue: [
			closing := pattern findString: ':]' startingAt: position + 1.
			(closing > 0 and: [ (self firstClosingBracketFrom: position + 1) = (closing + 1) ]) ifTrue: [
					property := pattern copyFrom: position + 1 to: closing - 1.
					position := closing + 2.
					^ self classNodeFor: (self propertyPredicate: property) ] ].
	(character = $[ and: [ (options bitAnd: PCRE2 altExtendedClass) ~= 0 ]) ifTrue: [
			nested := self utsClass.
			utsNestedClassClosed := true.
			^ nested ].
	^ self literal: character
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> classExpressionClosing: delimiter [

	| previousDelimiter previousStart predicate |
	previousDelimiter := classExpressionDelimiter.
	previousStart := classExpressionStart.
	classExpressionDelimiter := delimiter.
	classExpressionStart := position.
	[
		predicate := self classUnion.
		self classExpressionIgnored.
		self peek = delimiter ifFalse: [
				self atEnd ifTrue: [ self syntaxErrorCode: self unterminatedClassExpressionCode ].
				(delimiter = $) and: [ self peek = $] ]) ifTrue: [ self syntaxErrorCode: 114 ].
				(delimiter = $] and: [ self peek = $) ]) ifTrue: [
						self next.
						self syntaxErrorCode: 122 ].
				self unexpectedClassExpression ].
		self next.
		^ predicate ] ensure: [
			classExpressionDelimiter := previousDelimiter.
			classExpressionStart := previousStart ]
]

{ #category : 'scanning' }
PCRE2PatternParser >> classExpressionIgnored [

	[
		self skipClassIgnored.
		self peek isNotNil and: [ self peek isSeparator ] ] whileTrue: [ position := position + 1 ]
]

{ #category : 'parsing - classes' }
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

{ #category : 'parsing - classes' }
PCRE2PatternParser >> classNodeFor: aPredicate [
	"A node for a character class. It carries a table of the codes under 256 it accepts, since a class is asked once for every character of a subject."

	| node |
	node := PCRE2CharacterNode new predicate: aPredicate.
	node tabulate.
	^ node
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> classOperand [

	| character predicate node |
	self classExpressionIgnored.
	self atEnd ifTrue: [ self syntaxErrorCode: self unterminatedClassExpressionCode ].
	character := self next.
	character = $! ifTrue: [
			predicate := self classOperand.
			^ [ :candidate | (predicate value: candidate) not ] ].
	character = $( ifTrue: [ ^ self withExtendedClassDo: [ self classExpressionClosing: $) ] ].
	character = $[ ifTrue: [
			self peek = $: ifTrue: [
					position := position - 1.
					^ self classElement predicate ].
			^ self characterClass predicate ].
	character = $\ ifTrue: [
			self peek = $E ifTrue: [
					self next.
					^ self classOperand ].
			self peek = $Q ifTrue: [
					self next.
					(self peek = $\ and: [ position < pattern size and: [ (pattern at: position + 1) = $E ] ]) ifTrue: [
							position := position + 2.
							^ self classOperand ].
					self atEnd ifFalse: [ self next ].
					self syntaxErrorCode: 216 ].
			node := self parseEscapeInClass: true.
			(node isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxErrorCode: 216 ].
			^ node predicate ].
	(character = $] and: [ classExpressionDelimiter = $) ]) ifTrue: [
			position := position - 1.
			self syntaxErrorCode: 114 ].
	(character = $) and: [ classExpressionDelimiter = $] ]) ifTrue: [ self syntaxErrorCode: 122 ].
	(character = $] or: [ character = $) ]) ifTrue: [ self syntaxErrorCode: 214 ].
	('+|-^&' includes: character) ifTrue: [ self syntaxErrorCode: 209 ].
	self syntaxErrorCode: 216
]

{ #category : 'parsing - classes' }
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

{ #category : 'scanning' }
PCRE2PatternParser >> codeUnitOffsetAt: index [

	^ patternOffsets at: index
]

{ #category : 'accessing' }
PCRE2PatternParser >> codeUnitWidth: width [

	codeUnitWidth := width
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> combineClass: left with: right operator: operator [

	operator = $& ifTrue: [ ^ [ :character | (left value: character) and: [ right value: character ] ] ].
	operator = $- ifTrue: [ ^ [ :character | (left value: character) and: [ (right value: character) not ] ] ].
	operator = $^ ifTrue: [ ^ [ :character | (left value: character) ~= (right value: character) ] ].
	^ [ :character | (left value: character) or: [ right value: character ] ]
]

{ #category : 'accessing' }
PCRE2PatternParser >> compiledOptions [

	^ compiledOptions
]

{ #category : 'validation' }
PCRE2PatternParser >> conditionalAssertionAllowingCallout: allowCallout [

	| next following end name |
	next := position < pattern size ifTrue: [ pattern at: position + 1 ].
	following := position + 1 < pattern size ifTrue: [ pattern at: position + 2 ].
	self peek = $? ifTrue: [
			((#( $= $! ) includes: next) or: [ (next = $< and: [ #( $= $! ) includes: following ]) or: [ next = $C and: [ allowCallout ] ] ])
				ifFalse: [ self syntaxErrorCode: 128 ].
			^ self group ].
	(self peek = $* and: [ next isNotNil and: [ next between: $a and: $z ] ]) ifFalse: [ self syntaxErrorCode: 128 ].
	end := position + 1.
	[ end <= pattern size and: [ self isCaptureNameCharacter: (pattern at: end) ] ] whileTrue: [ end := end + 1 ].
	name := pattern copyFrom: position + 1 to: end - 1.
	(#( 'atomic' 'sr' 'script_run' 'asr' 'atomic_script_run' 'scs' 'scan_substring' 'napla' 'non_atomic_positive_lookahead'
	    'naplb' 'non_atomic_positive_lookbehind' ) includes: name) ifTrue: [
		self syntaxErrorCode: 128 atCodeUnit: (self codeUnitOffsetAt: end) ].
	^ self group
]

{ #category : 'parsing' }
PCRE2PatternParser >> conditionalRestoring: savedOptions [

	| condition yes no assertion reference text prefix conditionStart delimiter quoted recursion knownNames unsupported definition groupStart constantFalse elseWritten version |
	conditionStart := position.
	groupStart := position - 3.
	definition := false.
	constantFalse := false.
	elseWritten := false.
	knownNames := names.
	unsupported := false.
	prefix := OrderedCollection new.
	(self peek = $? or: [ self peek = $* ])
		ifTrue: [
				assertion := self conditionalAssertionAllowingCallout: true.
				(assertion isKindOf: PCRE2CalloutNode) ifTrue: [
						prefix add: assertion.
						self skipIgnored.
						self peek = $( ifFalse: [ self syntaxErrorCode: 128 ].
						self next.
						assertion := self conditionalAssertionAllowingCallout: false ].
				self validateLookaroundResetsIn: assertion active: true.
				condition := [ :engine :state | assertion conditionalIn: engine state: state ] ]
		ifFalse: [
				reference := self readReferenceNumber.
				reference ifNotNil: [
						reference = 0 ifTrue: [ self syntaxErrorCode: 115 ].
						self registerReference: reference at: position - 2.
						condition := [ :engine :state | engine captureIsSet: reference state: state ].
						unsupported := true ].
				condition ifNil: [
						(pattern size - position + 1 >= 10 and: [
							 (pattern findString: 'VERSION' startingAt: position) = position and: [ (pattern at: position + 7) ~= $) ] ])
							ifTrue: [
									version := self versionCondition.
									constantFalse := version not.
									condition := [ :engine :state | version ] ]
							ifFalse: [
									quoted := self peek = $< or: [ self peek = $' ].
									delimiter := nil.
									quoted ifTrue: [
											delimiter := self next = $<
												             ifTrue: [ $> ]
												             ifFalse: [ $' ] ].
									recursion := (pattern findString: 'R&' startingAt: position) = position and: [ quoted not ].
									recursion ifTrue: [ position := position + 2 ].
									conditionStart := position.
									text := self readCaptureNameUntil: delimiter.
									recursion
										ifTrue: [
												self registerReference: text at: conditionStart.
												condition := [ :engine :state | engine isRecursing: text state: state ] ]
										ifFalse: [
												(quoted not and: [ text = 'DEFINE' ])
													ifTrue: [
															definition := true.
															constantFalse := true.
															condition := [ :engine :state | false ] ]
													ifFalse: [
															(quoted not and: [
																 text first = $R and: [ text allButFirst allSatisfy: [ :character | character between: $0 and: $9 ] ] ])
																ifTrue: [
																		self registerRecursionCondition: text at: conditionStart.
																		reference := text size = 1
																			             ifTrue: [ nil ]
																			             ifFalse: [ text allButFirst asInteger ].
																		reference = 0 ifTrue: [ reference := nil ].
																		condition := [ :engine :state |
																			             (knownNames includes: text)
																				             ifTrue: [ engine captureIsSet: text state: state ]
																				             ifFalse: [ engine isRecursing: reference state: state ] ].
																		unsupported := [ knownNames includes: text ] ]
																ifFalse: [
																		self registerReference: text at: conditionStart.
																		condition := [ :engine :state | engine captureIsSet: text state: state ].
																		unsupported := true ] ] ].
									self peek = $) ifFalse: [ self syntaxErrorCode: 124 ].
									self next ] ].
				(reference isInteger and: [ text isNil ]) ifTrue: [
						self peek = $) ifFalse: [ self syntaxErrorCode: 124 ].
						self next ] ].
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		yes := self sequence.
		no := PCRE2SequenceNode new children: #(  ).
		self peek = $| ifTrue: [
				definition ifTrue: [ self syntaxErrorCode: 154 atCodeUnit: (self codeUnitOffsetAt: conditionStart) ].
				self next.
				elseWritten := true.
				no := self sequence.
				self peek = $| ifTrue: [ self syntaxErrorCode: 127 atCodeUnit: (self codeUnitOffsetAt: groupStart) ] ].
		self expect: $) errorCode: 114 ] ensure: [
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
	^ PCRE2ConditionalNode new
		  prefix: prefix asArray;
		  definition: definition;
		  dfaUnsupported: unsupported;
		  assertion: assertion;
		  hasElse: elseWritten;
		  neverRuns: (constantFalse and: [ elseWritten not ]);
		  byteCondition: (self
				   byteConditionFor: prefix
				   constant: constantFalse
				   numbered: ((reference isInteger and: [ text isNil ]) ifTrue: [ reference ])
				   version: version);
		  condition: condition then: yes else: no
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> controlEscape [

	| character |
	self atEnd ifTrue: [ self syntaxError: '\c at end of pattern' ].
	character := self next.
	(character asInteger between: 32 and: 126) ifFalse: [ self syntaxError: '\c must be followed by a printable ASCII character' ].
	^ self literalCodePoint: (character asUppercase asInteger bitXor: 64)
]

{ #category : 'scanning' }
PCRE2PatternParser >> decimal [

	| value |
	value := 0.
	[ self peek isNotNil and: [ self peek between: $0 and: $9 ] ] whileTrue: [
		value := value * 10 + self next asciiValue - $0 asciiValue ].
	^ value
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> endBeforeFinalNewlinePredicate [
	"\Z, and $ outside multiline mode: the end of the subject, or just before the line terminator that ends it."

	| convention crlf |
	convention := newlineConvention.
	crlf := convention mode = PCRE2 newlineCRLF.
	^ [ :engine :state |
		  | index trueEnd newline |
		  index := state position.
		  trueEnd := engine subject codeUnitCount.
		  newline := convention lengthAt: index + 1 in: engine subject.
		  (index = trueEnd or: [ newline > 0 and: [ index + newline = trueEnd ] ])
			  ifTrue: [
					  engine noteEndOfSubject: state.
					  true ]
			  ifFalse: [ "A CR in the last position may still turn out to be the first half of the CRLF this convention wants."
					  (crlf and: [ index = (engine subject size - 1) and: [ (engine subject codeUnitAtOffset: index) = 13 ] ]) ifTrue: [
						  engine noteEndOfSubject: state ].
					  false ] ]
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> endOfLineInMultilinePredicate [
	"$ in multiline mode: before any line terminator, or at the end of the subject unless PCRE2_NOTEOL applies."

	| convention crlf |
	convention := newlineConvention.
	crlf := convention mode = PCRE2 newlineCRLF.
	^ [ :engine :state |
		  | index size |
		  index := state position.
		  size := engine subject size.
		  index < size
			  ifTrue: [
					  (convention lengthAt: index + 1 in: engine subject) > 0 or: [ "A CR in the last position may still turn out to be the first half of the CRLF this convention wants."
							  (crlf and: [ index = (size - 1) and: [ (engine subject codeUnitAtOffset: index) = 13 ] ]) ifTrue: [
								  engine noteEndOfSubject: state ].
							  false ] ]
			  ifFalse: [
					  (engine matchOptions bitAnd: PCRE2 notEOL) ~= 0
						  ifTrue: [ false ]
						  ifFalse: [
								  engine notePartial: state.
								  true ] ] ]
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> endOfLinePredicate [
	"$: before any line terminator in multiline mode, otherwise what \Z asserts, or what \z asserts under PCRE2_DOLLAR_ENDONLY. PCRE2_NOTEOL rules it out outside multiline mode."

	| inner |
	(options bitAnd: PCRE2 multiline) ~= 0 ifTrue: [ ^ self endOfLineInMultilinePredicate ].
	inner := (options bitAnd: PCRE2 dollarEndOnly) ~= 0
		         ifTrue: [ self endOfSubjectPredicate ]
		         ifFalse: [ self endBeforeFinalNewlinePredicate ].
	^ [ :engine :state | (engine matchOptions bitAnd: PCRE2 notEOL) = 0 and: [ inner value: engine value: state ] ]
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> endOfSubjectPredicate [
	"\z: the very end of the subject, which narrowing to one fragment of valid UTF does not move."

	^ [ :engine :state |
		  | held |
		  held := state position = engine subject codeUnitCount.
		  held ifTrue: [ engine noteEndOfSubject: state ].
		  held ]
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> escapeInClass: inClass [

	| start |
	start := position.
	^ [ self parseEscapeInClass: inClass ]
		  on: PCRE2CompileError
		  do: [ :error |
				  ((extraOptions bitAnd: PCRE2 extraBadEscapeIsLiteral) = 0 or: [
					   inClass and: [ #( 107 171 ) anySatisfy: [ :code | error errorMessage = (PCRE2 translateErrorCode: code) ] ] ]) ifTrue: [
					  error pass ].
				  position := start.
				  self literal: (self atEnd
						   ifTrue: [ $\ ]
						   ifFalse: [ self next ]) ]
]

{ #category : 'scanning' }
PCRE2PatternParser >> expect: character errorCode: errorCode [
	"Consume character, or report the PCRE2 error that names what is missing."

	self peek = character ifFalse: [ self syntaxErrorCode: errorCode ].
	self next
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> expectAlphaAssertionColon [

	self atEnd ifTrue: [ self syntaxErrorCode: 114 ].
	self next = $: ifFalse: [ self syntaxErrorCode: 195 ]
]

{ #category : 'callouts' }
PCRE2PatternParser >> explicitCallout [

	| number text delimiter start numeric |
	(extraOptions bitAnd: PCRE2 extraNeverCallout) ~= 0 ifTrue: [ self syntaxError: 'callout is not allowed' ].
	number := 0.
	numeric := self peek isNotNil and: [ self peek between: $0 and: $9 ].
	numeric ifTrue: [
			number := self decimal.
			number > 255 ifTrue: [ self syntaxError: 'number after (?C is greater than 255' ] ].
	(numeric not and: [ self peek isNotNil and: [ #( 39 34 96 94 37 35 36 123 ) includes: self peek asInteger ] ])
		ifTrue: [
				delimiter := self next.
				delimiter = (Character value: 123) ifTrue: [ delimiter := $} ].
				start := position.
				text := self readCalloutStringUntil: delimiter ]
		ifFalse: [
				(numeric not and: [ self atEnd not and: [ self peek ~= $) ] ]) ifTrue: [
						self next.
						self syntaxErrorCode: 182 ] ].
	self peek = $) ifFalse: [ self syntaxErrorCode: 139 ].
	self next.
	^ self
		  newCallout: number
		  string: text
		  stringStart: start
		  position: position
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> extendedClass [

	^ self withExtendedClassDo: [ self parseExtendedClass ]
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

{ #category : 'accessing' }
PCRE2PatternParser >> extraOptions: flags [

	extraOptions := flags
]

{ #category : 'scanning' }
PCRE2PatternParser >> firstClosingBracketFrom: start [

	| index |
	index := start.
	[ index <= pattern size ] whileTrue: [
			(pattern at: index) = $] ifTrue: [ ^ index ].
			index := index + ((pattern at: index) = $\
				          ifTrue: [ 2 ]
				          ifFalse: [ 1 ]) ].
	^ 0
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> group [

	| savedOptions index name body character positive capture groupStart |
	groupStart := position - 1.
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
					self readUntil: $) errorCode: 118.
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
							^ (self lookbehind: (self groupBodyRestoring: savedOptions) positive: true startingAt: groupStart) atomic: false ].
					(self peek = $= or: [ self peek = $! ]) ifTrue: [
							positive := self next = $=.
							^ self lookbehind: (self groupBodyRestoring: savedOptions) positive: positive startingAt: groupStart ].
					name := self readCaptureNameUntil: $> ].
			character = $' ifTrue: [ name := self readCaptureNameUntil: $' ].
			character = $P ifTrue: [
					self peek = $> ifTrue: [
							position := position + 1.
							name := self readSubroutineName.
							self registerReference: name at: position - name size.
							^ self subroutineNode: name ].
					self peek = $= ifTrue: [
							position := position + 1.
							^ PCRE2BackreferenceNode new
								  reference: (self noteBackreference: self namedBackreference);
								  options: options;
								  extraOptions: extraOptions ].
					self peek = $< ifFalse: [ self syntaxErrorCode: 141 atCodeUnit: self offsetAfterCurrent ].
					self next.
					name := self readCaptureNameUntil: $> ].
			character = $R ifTrue: [ ^ self subroutineNode: 0 closingErrorCode: 158 ].
			character = $& ifTrue: [
					name := self readSubroutineName.
					self registerReference: name at: position - name size.
					^ self subroutineNode: name ].
			(character between: $0 and: $9) ifTrue: [
					position := position - 1.
					index := self readReferenceNumber.
					self registerReference: index.
					^ self subroutineNode: index ].
			((character = $- or: [ character = $+ ]) and: [ self peek isNotNil and: [ self peek isDigit ] ]) ifTrue: [
					position := position - 1.
					index := self readReferenceNumber.
					self registerReference: index.
					^ self subroutineNode: index ].
			character = $+ ifTrue: [ self syntaxErrorCode: 129 atCodeUnit: self offsetAfterCurrent ].
			name ifNil: [
					('imsxUJ-n^ar' includes: character) ifTrue: [
							position := position - 1.
							self inlineOptions.
							self peek = $) ifTrue: [
									position := position + 1.
									^ PCRE2SequenceNode new children: #(  ) ].
							self expect: $: errorCode: 114.
							^ self groupBodyRestoring: savedOptions ].
					self syntaxError: 'unrecognized character after (? or (?-' ].
			capture := true ].
	capture ifFalse: [ ^ self groupBodyRestoring: savedOptions ].
	captureCount >= 65535 ifTrue: [ self syntaxErrorCode: 197 ].
	captureCount := captureCount + 1.
	index := captureCount.
	name ifNotNil: [
			((names includes: name) and: [ (names at: index ifAbsent: [ nil ]) ~= name and: [ (options bitAnd: PCRE2 dupNames) = 0 ] ])
				ifTrue: [ self syntaxErrorCode: 143 ].
			(names at: index ifAbsent: [ name ]) = name ifFalse: [ self syntaxErrorCode: 165 ].
			names at: index put: name ].
	body := PCRE2CaptureNode new index: index.
	groups at: index ifAbsentPut: [ body ].
	body child: (self groupBodyRestoring: savedOptions).
	^ body
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> groupBodyRestoring: savedOptions [

	| body |
	depth := depth + 1.
	depth > nestLimit ifTrue: [ self syntaxError: 'parentheses are too deeply nested' ].
	[
		body := self alternation.
		self expect: $) errorCode: 114 ] ensure: [
			depth := depth - 1.
			options := savedOptions first.
			extraOptions := savedOptions second ].
	^ body
]

{ #category : 'accessing' }
PCRE2PatternParser >> groups [

	^ groups
]

{ #category : 'accessing' }
PCRE2PatternParser >> groups: aDictionary [

	groups := aDictionary
]

{ #category : 'validation' }
PCRE2PatternParser >> hasBackreferenceIn: node [

	(node isKindOf: PCRE2BackreferenceNode) ifTrue: [ ^ true ].
	^ (self patternChildrenOf: node) anySatisfy: [ :child | self hasBackreferenceIn: child ]
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> hexadecimalEscape [

	| digits start |
	(self atEnd and: [ self altBSUX not ]) ifTrue: [ self syntaxErrorCode: 178 ].
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
				^ self literalCodePoint: (self bracedNumberInBase: 16 invalidCode: 167) ]
		ifFalse: [
				digits := String streamContents: [ :stream |
					          2 timesRepeat: [
						          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ].
				digits isEmpty ifTrue: [ self syntaxErrorCode: 178 ] ].
	^ self literalCodePoint: (Integer readFrom: digits readStream base: 16)
]

{ #category : 'scanning' }
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

{ #category : 'parsing - groups' }
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

{ #category : 'scanning' }
PCRE2PatternParser >> isCaptureNameCharacter: character [

	character ifNil: [ ^ false ].
	^ character = $_ or: [
			  (options bitAnd: PCRE2 utf) ~= 0
				  ifTrue: [
					  (PCRE2UnicodeData matches: 'gc:l' code: character asInteger) or: [
						  PCRE2UnicodeData matches: 'gc:nd' code: character asInteger ] ]
				  ifFalse: [ character asInteger < 128 and: [ character isAlphaNumeric ] ] ]
]

{ #category : 'validation' }
PCRE2PatternParser >> isRecursiveLength: node visiting: active [

	| target index next |
	(active includes: node) ifTrue: [ ^ true ].
	next := active copy
		        add: node;
		        yourself.
	((node isKindOf: PCRE2SubroutineNode) or: [ node isKindOf: PCRE2BackreferenceNode ]) ifTrue: [
			index := node reference isInteger
				         ifTrue: [ node reference ]
				         ifFalse: [ names keyAtValue: node reference ifAbsent: [ nil ] ].
			target := groups at: index ifAbsent: [ ^ false ].
			^ self isRecursiveLength: target visiting: next ].
	^ (self patternChildrenOf: node) anySatisfy: [ :child | self isRecursiveLength: child visiting: next ]
]

{ #category : 'parsing - escapes' }
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

{ #category : 'parsing - escapes' }
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
	code > maximum ifTrue: [ self syntaxErrorCode: 134 ].
	((options bitAnd: PCRE2 utf) ~= 0 and: [
		 (code between: 16rD800 and: 16rDFFF) and: [ (extraOptions bitAnd: PCRE2 extraAllowSurrogateEscapes) = 0 ] ]) ifTrue: [
		self syntaxErrorCode: 173 ].
	^ self literal: (PCRE2CodeUnit fromInteger: code)
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> longGroupRestoring: savedOptions [

	| name argument kinds child selection groupStart |
	groupStart := position - 1.
	self expect: $* errorCode: 160.
	self peek = $) ifTrue: [ self syntaxErrorCode: 109 ].
	self atEnd ifTrue: [ self syntaxErrorCode: 109 ].
	name := String streamContents: [ :stream |
			        [ self peek isNotNil and: [ self peek asInteger < 128 and: [ self peek isAlphaNumeric or: [ self peek = $_ ] ] ] ]
				        whileTrue: [ stream nextPut: self next ] ].
	(#( 'scs' 'scan_substring' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			selection := self captureReferenceList.
			child := self groupBodyRestoring: savedOptions.
			^ PCRE2ScanSubstringNode new
				  child: child;
				  references: selection;
				  positive: true ].
	(#( 'napla' 'non_atomic_positive_lookahead' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			^ PCRE2LookaheadNode new
				  child: (self groupBodyRestoring: savedOptions);
				  positive: true;
				  atomic: false ].
	(#( 'naplb' 'non_atomic_positive_lookbehind' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			^ (self lookbehind: (self groupBodyRestoring: savedOptions) positive: true startingAt: groupStart) atomic: false ].
	(#( 'pla' 'positive_lookahead' 'nla' 'negative_lookahead' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			^ PCRE2LookaheadNode new
				  child: (self groupBodyRestoring: savedOptions);
				  positive: (#( 'pla' 'positive_lookahead' ) includes: name) ].
	(#( 'plb' 'positive_lookbehind' 'nlb' 'negative_lookbehind' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			^ self
				  lookbehind: (self groupBodyRestoring: savedOptions)
				  positive: (#( 'plb' 'positive_lookbehind' ) includes: name)
				  startingAt: groupStart ].
	(#( 'sr' 'script_run' 'asr' 'atomic_script_run' ) includes: name) ifTrue: [
			self expectAlphaAssertionColon.
			child := self groupBodyRestoring: savedOptions.
			(#( 'asr' 'atomic_script_run' ) includes: name) ifTrue: [ child := PCRE2AtomicNode new child: child ].
			^ PCRE2ScriptRunNode new child: child ].
	name = 'atomic' ifTrue: [
			self expectAlphaAssertionColon.
			^ PCRE2AtomicNode new child: (self groupBodyRestoring: savedOptions) ].
	(name isNotEmpty and: [ name first between: $a and: $z ]) ifTrue: [ self syntaxErrorCode: 195 ].
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
	((kinds includesKey: name) not or: [ self peek ~= $: and: [ self peek ~= $) ] ]) ifTrue: [ self rejectVerbName: name ].
	((kinds at: name) = #mark and: [ self peek = $) ]) ifTrue: [ self syntaxErrorCode: 166 ].
	self peek = $:
		ifTrue: [
				self next.
				self peek = $)
					ifTrue: [
							(kinds at: name) = #mark ifTrue: [ self syntaxErrorCode: 166 ].
							self next ]
					ifFalse: [ argument := self readVerbArgument ] ]
		ifFalse: [ self next ].
	^ PCRE2ControlNode new kind: (self noteVerb: (kinds at: name)) name: argument
]

{ #category : 'parsing - groups' }
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

{ #category : 'parsing - groups' }
PCRE2PatternParser >> lookbehind: body positive: positive startingAt: index [

	| node |
	node := self lookbehind: body positive: positive.
	lookbehindPositions at: node put: (self codeUnitOffsetAt: index).
	^ node
]

{ #category : 'validation' }
PCRE2PatternParser >> lookbehindBranchCount: node upTo: maximum [

	| count index target |
	((node isKindOf: PCRE2LookaheadNode) or: [ node isKindOf: PCRE2LookbehindNode ]) ifTrue: [ ^ 0 ].
	((node isKindOf: PCRE2SubroutineNode) or: [ node isKindOf: PCRE2BackreferenceNode ]) ifTrue: [
			index := node reference isInteger
				         ifTrue: [ node reference ]
				         ifFalse: [ names keyAtValue: node reference ifAbsent: [ nil ] ].
			target := groups at: index ifAbsent: [ ^ 0 ].
			^ self lookbehindBranchCount: target upTo: maximum ].
	count := (node isKindOf: PCRE2SequenceNode)
		         ifTrue: [ 1 ]
		         ifFalse: [ 0 ].
	(self patternChildrenOf: node) do: [ :child |
			count := count + (self lookbehindBranchCount: child upTo: maximum - count).
			count > maximum ifTrue: [ ^ count ] ].
	^ count
]

{ #category : 'accessing' }
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

{ #category : 'parsing - groups' }
PCRE2PatternParser >> namedBackreference [

	| name start |
	start := position.
	name := self readCaptureNameUntil: $).
	self registerReference: name at: start.
	^ name
]

{ #category : 'accessing' }
PCRE2PatternParser >> names [

	^ names
]

{ #category : 'accessing' }
PCRE2PatternParser >> names: aDictionary [

	names := aDictionary
]

{ #category : 'accessing' }
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

{ #category : 'accessing' }
PCRE2PatternParser >> newlineMode [

	^ newlineConvention mode
]

{ #category : 'scanning' }
PCRE2PatternParser >> next [

	| character |
	self atEnd ifTrue: [ self syntaxError: 'unexpected end of pattern' ].
	character := pattern at: position.
	position := position + 1.
	^ character
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> normalizedReference: text [

	| trimmed number index |
	trimmed := text trimBoth.
	trimmed isEmpty ifTrue: [ self syntaxError: 'empty reference' ].
	((trimmed first isDigit or: [ trimmed first = $- or: [ trimmed first = $+ ] ]) and: [
		 trimmed allSatisfy: [ :character | character isDigit or: [ character = $- or: [ character = $+ ] ] ] ]) ifFalse: [ ^ trimmed ].
	number := [ trimmed asInteger ]
		          on: Error
		          do: [ :error | self syntaxError: 'invalid subpattern reference' ].
	trimmed first = $- ifTrue: [
			(number = 0 or: [ captureCount + number + 1 <= 0 ]) ifTrue: [
					index := (position > 1 and: [ (pattern at: position - 1) = $) ])
						         ifTrue: [ position - 1 ]
						         ifFalse: [ position ].
					self syntaxErrorCode: 115 atCodeUnit: (self codeUnitOffsetAt: index) ].
			^ captureCount + number + 1 ].
	trimmed first = $+ ifTrue: [
			number = 0 ifTrue: [ self syntaxError: 'invalid relative subpattern number' ].
			^ captureCount + number ].
	^ number
]

{ #category : 'parsing - optimization' }
PCRE2PatternParser >> noteBackreference: reference [
	"Record what a backreference points at. PCRE2 refuses to read a leading dot star as saying where a match begins when it sits in a group something refers back to, because the group can then be asked to have matched something else."

	backreferences add: reference.
	^ reference
]

{ #category : 'parsing - optimization' }
PCRE2PatternParser >> noteVerb: kind [
	"Record a verb that breaks the leading dot star optimization. PCRE2 gives it up for the whole pattern as soon as (*PRUNE) or (*SKIP) appears anywhere in it."

	(kind = #prune or: [ kind = #skip ]) ifTrue: [ hadPruneOrSkip := true ].
	^ kind
]

{ #category : 'parsing - escapes' }
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
			self registerReference: reference.
			^ PCRE2BackreferenceNode new
				  reference: (self noteBackreference: reference);
				  options: options;
				  extraOptions: extraOptions ].
	position := saved.
	^ self octalEscape
]

{ #category : 'parsing - escapes' }
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

{ #category : 'signalling' }
PCRE2PatternParser >> offsetAfterCurrent [
	"The code-unit offset one character past the one at the current position. PCRE2 blames several diagnostics there."

	^ self codeUnitOffsetAt: (position + 1 min: pattern size + 1)
]

{ #category : 'parsing' }
PCRE2PatternParser >> parse [

	| result |
	result := self alternation.
	self skipIgnored.
	self atEnd ifFalse: [
			position := position + 1.
			self syntaxError: 'unmatched closing parenthesis' ].
	references do: #value.
	self validateLookbehinds.
	self validateLookaroundResetsIn: result active: false.
	calloutSites do: [ :site | site nextItemLength: (itemLengths at: site patternPosition ifAbsent: [ 0 ]) ].
	^ result
]

{ #category : 'parsing' }
PCRE2PatternParser >> parse: preparedInput options: compileOptions [

	| prefix tree result |
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
	referenceOffsets := Dictionary new.
	lookbehindPositions := IdentityDictionary new.
	backreferences := OrderedCollection new.
	hadPruneOrSkip := false.
	branchResetUsed := false.
	requiresPreviousCharacter := false.
	extendedClassDepth := 0.
	lookbehinds := OrderedCollection new.
	prefix := self extraMatchingBoundary: true.
	tree := (options bitAnd: PCRE2 literal) ~= 0
		        ifTrue: [ PCRE2SequenceNode new children: (pattern collect: [ :character | self literal: character ] as: Array) ]
		        ifFalse: [ self parse ].
	result := prefix ifNil: [ tree ] ifNotNil: [
			          PCRE2SequenceNode new children: {
					          prefix.
					          tree.
					          (self extraMatchingBoundary: false) } ].
	self analyseStartOf: result.
	^ result
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> parseCharacterClass [

	| negative predicates first node end caseless closing tests |
	(pattern findString: '[:<:]]' startingAt: position) = position ifTrue: [
			position := position + 6.
			^ self posixWordBoundary: true ].
	(pattern findString: '[:>:]]' startingAt: position) = position ifTrue: [
			position := position + 6.
			^ self posixWordBoundary: false ].
	(self peek isNotNil and: [ '.=:' includes: self peek ]) ifTrue: [
			closing := pattern findString: (String with: self peek with: $]) startingAt: position + 1.
			(closing > 0 and: [
					 ((pattern copyFrom: position + 1 to: closing - 1) includes: $[) not and: [
						 (self firstClosingBracketFrom: position + 1) = (closing + 1) ] ]) ifTrue: [
					self
						syntaxErrorCode: (self peek = $:
								 ifTrue: [ 112 ]
								 ifFalse: [ 113 ])
						atCodeUnit: (self codeUnitOffsetAt: closing + 2) ] ].
	(options bitAnd: PCRE2 altExtendedClass) ~= 0 ifTrue: [ ^ self utsClass ].
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
					node children ifEmpty: [ self syntaxErrorCode: 106 ].
					node children allButLast do: [ :quoted | predicates add: quoted predicate ].
					node := node children last ].
			(node isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxErrorCode: 107 ].
			self skipClassIgnored.
			(self peek = $- and: [ position < pattern size and: [ (pattern at: position + 1) ~= $] ] ])
				ifTrue: [
						position := position + 1.
						self skipClassIgnored.
						self peek = $]
							ifTrue: [
									predicates
										add: node predicate;
										add: (self literal: $-) predicate ]
							ifFalse: [
									node character ifNil: [ self syntaxErrorCode: 150 ].
									end := self classElementAsRangeEnd: true.
									(end isKindOf: PCRE2QuotedSequenceNode) ifTrue: [
											end children ifEmpty: [ self syntaxErrorCode: 106 ].
											end children allButFirst do: [ :quoted | predicates add: quoted predicate ].
											end := end children first ].
									(end isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxErrorCode: 150 ].
									(node character isNil or: [ end character isNil ]) ifTrue: [ self syntaxErrorCode: 150 ].
									node character > end character ifTrue: [ self syntaxErrorCode: 108 ].
									caseless := (options bitAnd: PCRE2 caseless) ~= 0.
									predicates add: (self rangeFrom: node character to: end character caseless: caseless) ] ]
				ifFalse: [ predicates add: node predicate ].
			first := false.
			self skipClassIgnored ].
	self expect: $] errorCode: 106.
	tests := predicates asArray.
	"Both sides below are booleans, so identity settles the negation without a comparison send on a path walked for every character."
	^ self classNodeFor: [ :candidate | (tests anySatisfy: [ :test | test value: candidate ]) ~~ negative ]
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> parseEscapeInClass: inClass [

	| character reference start nodes property predicate code |
	self atEnd ifTrue: [ self syntaxErrorCode: 101 ].
	character := self next.
	('dDsSwWhHvV' includes: character) ifTrue: [ ^ self classNodeFor: (self predicateFor: character) ].
	character = $C ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
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
	character = $B ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #notWordBoundary ].
	character = $A ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #beginSubject ].
	character = $z ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #endSubject ].
	character = $Z ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #endBeforeFinalNewline ].
	character = $G ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #startMatch ].
	character = $K ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ self assertion: #resetStart ].
	character = $R ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ PCRE2NewlineNode new convention: (PCRE2NewlineConvention new mode: (bsr = PCRE2 bsrAnyCRLF
						    ifTrue: [ PCRE2 newlineAnyCRLF ]
						    ifFalse: [ PCRE2 newlineAny ])) ].
	character = $N ifTrue: [
			self peek = (Character value: 123) ifTrue: [
					start := position.
					self next.
					[ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ].
					(pattern findString: 'U+' startingAt: position) = position ifTrue: [
							position := position + 2.
							code := self bracedNumberInBase: 16 invalidCode: 167.
							(options bitAnd: PCRE2 utf) = 0 ifTrue: [ self syntaxErrorCode: 193 ].
							^ self literalCodePoint: code ].
					position := start.
					inClass ifFalse: [
							reference := self quantifierBounds.
							position := start.
							reference ifNotNil: [ ^ PCRE2DotNode new convention: newlineConvention dotAll: false ] ].
					self next.
					self syntaxErrorCode: 137 ].
			inClass ifTrue: [ self syntaxErrorCode: 171 ].
			^ PCRE2DotNode new convention: newlineConvention dotAll: false ].
	(character = $p or: [ character = $P ]) ifTrue: [
			property := self peek = (Character value: 123)
				            ifTrue: [
						            position := position + 1.
						            self readUntil: $} errorCode: 146 ]
				            ifFalse: [ self next asString ].
			predicate := [ PCRE2UnicodeData predicateFor: property caseless: (options bitAnd: PCRE2 caseless) ~= 0 ]
				             on: PCRE2UnsupportedFeature
				             do: [ :error | self syntaxErrorCode: 147 ].
			character = $P ifTrue: [ ^ self classNodeFor: [ :candidate | (predicate value: candidate) not ] ].
			^ self classNodeFor: predicate ].
	(character between: $1 and: $9) ifTrue: [ ^ self numericEscapeInClass: inClass ].
	character = $0 ifTrue: [
			position := position - 1.
			^ self octalEscape ].
	(character = $k or: [ character = $g ]) ifTrue: [
			inClass ifTrue: [ ^ self literal: character ].
			^ self referenceEscape: character ].
	character = $X ifTrue: [
			inClass ifTrue: [ self syntaxErrorCode: 107 ].
			^ PCRE2GraphemeNode new ].
	character = $E ifTrue: [ ^ PCRE2SequenceNode new children: #(  ) ].
	character = $Q ifTrue: [
			start := position.
			[ self atEnd not and: [ (self peek = $\ and: [ position < pattern size and: [ (pattern at: position + 1) = $E ] ]) not ] ]
				whileTrue: [ position := position + 1 ].
			nodes := (pattern copyFrom: start to: position - 1) collect: [ :literal | self literal: literal ] as: Array.
			self atEnd ifFalse: [ position := position + 2 ].
			^ PCRE2QuotedSequenceNode new children: nodes ].
	('FLlUu' includes: character) ifTrue: [ self syntaxErrorCode: 137 ].
	(character asInteger < 128 and: [ character isAlphaNumeric ]) ifTrue: [ self syntaxError: 'unrecognized character follows \' ].
	^ self literal: character
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> parseExtendedClass [

	| predicate savedOptions savedExtraOptions |
	savedOptions := options.
	savedExtraOptions := extraOptions.
	extraOptions := extraOptions bitAnd: PCRE2 extraBadEscapeIsLiteral bitInvert.
	options := (options bitAnd: (PCRE2 altExtendedClass | PCRE2 allowEmptyClass) bitInvert) bitOr:
		           PCRE2 extended | PCRE2 extendedMore.
	[
		predicate := self classExpressionClosing: $].
		self peek = $) ifFalse: [ self syntaxErrorCode: 215 ].
		self next ] ensure: [
			options := savedOptions.
			extraOptions := savedExtraOptions ].
	^ self classNodeFor: predicate
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> parseUTSClass [

	| negative left operator previous right |
	self skipClassIgnored.
	negative := self peek = $^.
	negative ifTrue: [
			self next.
			self skipClassIgnored ].
	((options bitAnd: PCRE2 allowEmptyClass) ~= 0 and: [ self peek = $] ]) ifTrue: [
			self next.
			^ PCRE2CharacterNode new predicate: [ :candidate | negative ] ].
	left := self utsSegmentAllowingClosingLiteral: true.
	self skipClassIgnored.
	[ self utsOperator isNotNil ] whileTrue: [
			operator := self utsOperator.
			(previous isNotNil and: [ previous ~= operator ]) ifTrue: [
				self syntaxErrorCode: 211 atCodeUnit: (self codeUnitOffsetAt: position + 2) ].
			previous := operator.
			position := position + 2.
			right := self utsSegmentAllowingClosingLiteral: false.
			left := self combineClass: left with: right operator: (operator = $~
					         ifTrue: [ $^ ]
					         ifFalse: [ operator ]).
			self skipClassIgnored ].
	self expect: $] errorCode: self unterminatedUTSClassCode.
	^ self classNodeFor: [ :candidate | (left value: candidate) ~= negative ]
]

{ #category : 'validation' }
PCRE2PatternParser >> patternChildrenOf: node [

	| result |
	result := OrderedCollection new.
	1 to: node class allInstVarNames size do: [ :index |
			| value |
			value := node instVarAt: index.
			(value isKindOf: PCRE2PatternNode)
				ifTrue: [ result add: value ]
				ifFalse: [
						(value isCollection and: [ value isString not ]) ifTrue: [
							value do: [ :each | (each isKindOf: PCRE2PatternNode) ifTrue: [ result add: each ] ] ] ] ].
	^ result
]

{ #category : 'accessing' }
PCRE2PatternParser >> patternLimits [

	^ patternLimits
]

{ #category : 'accessing' }
PCRE2PatternParser >> patternMatchOptions [

	^ patternMatchOptions
]

{ #category : 'scanning' }
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

{ #category : 'parsing - classes' }
PCRE2PatternParser >> posixWordBoundary: beginning [

	| word assertion |
	word := self classNodeFor: (self predicateFor: $w).
	assertion := beginning
		             ifTrue: [
				             PCRE2LookaheadNode new
					             child: word;
					             positive: true ]
		             ifFalse: [ self lookbehind: word positive: true ].
	^ PCRE2SequenceNode new children: {
			  (self assertion: #wordBoundary).
			  assertion }
]

{ #category : 'parsing - classes' }
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

{ #category : 'parsing - classes' }
PCRE2PatternParser >> propertyPredicate: property [

	| unicode name |
	unicode := (options bitAnd: PCRE2 ucp) ~= 0.
	name := property first = $^
		        ifTrue: [ property allButFirst ]
		        ifFalse: [ property ].
	(#( 'alnum' 'alpha' 'ascii' 'blank' 'cntrl' 'digit' 'graph' 'lower' 'print' 'punct' 'space' 'upper' 'word' 'xdigit' ) includes:
		 name) ifFalse: [ self syntaxError: 'unknown POSIX class name' ].
	((extraOptions bitAnd: PCRE2 extraAsciiPosix) ~= 0 or: [
		 (extraOptions bitAnd: PCRE2 extraAsciiDigit) ~= 0 and: [ #( 'digit' 'xdigit' ) includes: name ] ]) ifTrue: [ unicode := false ].
	^ PCRE2UnicodeData posixPredicate: property unicode: unicode caseless: (options bitAnd: PCRE2 caseless) ~= 0
]

{ #category : 'parsing' }
PCRE2PatternParser >> quantifiedAtom [

	| node minimum maximum greedy repeat quantifier bounds lazy |
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
	node canBeRepeated not ifTrue: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
	self skipIgnored.
	greedy := (options bitAnd: PCRE2 ungreedy) = 0.
	lazy := self peek = $?.
	self peek = $? ifTrue: [
			greedy := greedy not.
			position := position + 1 ].
	repeat := node repeatMinimum: minimum maximum: maximum greedy: greedy.
	self peek = $+ ifTrue: [
			position := position + 1.
			lazy ifTrue: [ self syntaxError: 'quantifier does not follow a repeatable item' ].
			repeat greedy: true.
			^ PCRE2AtomicNode new
				  child: repeat;
				  possessive: true ].
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
	(maximum isNotNil and: [ minimum > maximum ]) ifTrue: [
			position := position - 1.
			self syntaxErrorCode: 104 ].
	(minimum > 65535 or: [ maximum isNotNil and: [ maximum > 65535 ] ]) ifTrue: [
			position := position - 1.
			self syntaxErrorCode: 105 ].
	^ {
		  minimum.
		  maximum }
]

{ #category : 'parsing - classes' }
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

	| stream character offset |
	offset := self codeUnitOffsetAt: position - 1.
	stream := WriteStream on: String new.
	[ self atEnd not ] whileTrue: [
			character := self next.
			character = delimiter ifTrue: [
					self peek = delimiter ifFalse: [ ^ stream contents ].
					self next ].
			stream nextPut: character ].
	self syntaxErrorCode: 181 atCodeUnit: offset
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> readCaptureNameUntil: delimiter [

	| start end name first digit |
	delimiter = $} ifTrue: [ [ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ] ].
	start := position.
	first := self peek.
	first ifNil: [ self syntaxErrorCode: 162 ].
	digit := (options bitAnd: PCRE2 utf) ~= 0
		         ifTrue: [ PCRE2UnicodeData matches: 'gc:nd' code: first asInteger ]
		         ifFalse: [ first between: $0 and: $9 ].
	digit ifTrue: [
			self next.
			self syntaxErrorCode: 144 ].
	[ self isCaptureNameCharacter: self peek ] whileTrue: [ self next ].
	end := position.
	name := pattern copyFrom: start to: end - 1.
	(self codeUnitOffsetAt: end) - (self codeUnitOffsetAt: start) > 128 ifTrue: [ self syntaxErrorCode: 148 ].
	start = end ifTrue: [ self syntaxErrorCode: 162 ].
	delimiter ifNotNil: [
			delimiter = $} ifTrue: [ [ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ] ].
			self peek = delimiter ifFalse: [ self syntaxErrorCode: 142 ].
			self next ].
	^ name
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> readReferenceNumber [

	| start sign number |
	start := position.
	sign := self peek.
	(sign = $+ or: [ sign = $- ]) ifTrue: [ self next ].
	(self peek isNotNil and: [ self peek between: $0 and: $9 ]) ifFalse: [
			position := start.
			^ nil ].
	number := self decimal.
	number > (sign = $+
		 ifTrue: [ 65535 - captureCount ]
		 ifFalse: [ 65535 ]) ifTrue: [ self syntaxErrorCode: 161 ].
	(sign = $+ or: [ sign = $- ]) ifTrue: [
			number = 0 ifTrue: [ self syntaxErrorCode: 126 ].
			sign = $- ifTrue: [
					number > captureCount ifTrue: [ self syntaxErrorCode: 115 ].
					^ captureCount + 1 - number ].
			^ captureCount + number ].
	^ number
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> readSubroutineName [

	^ self readCaptureNameUntil: nil
]

{ #category : 'scanning' }
PCRE2PatternParser >> readUntil: delimiter errorCode: errorCode [
	"Read up to the delimiter, reporting the PCRE2 error that names it when the pattern ends first."

	| start |
	start := position.
	[ self atEnd not and: [ self peek ~= delimiter ] ] whileTrue: [ position := position + 1 ].
	self atEnd ifTrue: [ self syntaxErrorCode: errorCode ].
	position := position + 1.
	^ pattern copyFrom: start to: position - 2
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> readVerbArgument [

	| start result |
	start := position.
	(options bitAnd: PCRE2 altVerbNames) = 0
		ifTrue: [ result := self readUntil: $) errorCode: 160 ]
		ifFalse: [
				result := String streamContents: [ :stream |
						          [ self atEnd not and: [ self peek ~= $) ] ] whileTrue: [
								          | character node |
								          character := self next.
								          ((options bitAnd: PCRE2 extended | PCRE2 extendedMore) ~= 0 and: [
									           #( 9 10 11 12 13 32 133 8206 8207 8232 8233 ) includes: character asInteger ]) ifFalse: [
										          ((options bitAnd: PCRE2 extended | PCRE2 extendedMore) ~= 0 and: [ character = $# ])
											          ifTrue: [ self skipPatternComment ]
											          ifFalse: [
													          character = $\
														          ifTrue: [
																          node := self parseEscapeInClass: false.
																          (node isKindOf: PCRE2SequenceNode)
																	          ifTrue: [ node children do: [ :each | stream nextPut: each character ] ]
																	          ifFalse: [
																			          (node isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxErrorCode: 140 ].
																			          node character ifNil: [ self syntaxErrorCode: 140 ].
																			          stream nextPut: node character ] ]
														          ifFalse: [ stream nextPut: character ] ] ] ] ].
				self expect: $) errorCode: 160 ].
	(self codeUnitOffsetAt: position - 1) - (self codeUnitOffsetAt: start) > 255 ifTrue: [
		self syntaxErrorCode: 176 atCodeUnit: (self codeUnitOffsetAt: position - 1) ].
	^ result
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> referenceEscape: character [

	| delimiter start reference subroutine |
	delimiter := nil.
	subroutine := false.
	(self peek = $< or: [ self peek = $' or: [ self peek = (Character value: 123) ] ])
		ifTrue: [
				delimiter := self next.
				delimiter := delimiter = $<
					             ifTrue: [ $> ]
					             ifFalse: [
							             delimiter = (Character value: 123)
								             ifTrue: [ $} ]
								             ifFalse: [ $' ] ].
				subroutine := character = $g and: [ delimiter ~= $} ].
				delimiter = $} ifTrue: [ [ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ] ].
				start := position.
				reference := character = $g ifTrue: [ self readReferenceNumber ].
				reference
					ifNil: [
							reference := self readCaptureNameUntil: delimiter.
							self registerReference: reference at: start ]
					ifNotNil: [
							delimiter = $} ifTrue: [ [ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ self next ] ].
							self peek = delimiter ifFalse: [ self syntaxErrorCode: 219 ].
							self next.
							(reference = 0 and: [ subroutine not ]) ifTrue: [ self syntaxErrorCode: 115 ].
							self registerReference: reference ] ]
		ifFalse: [
				character = $k ifTrue: [ self syntaxErrorCode: 169 ].
				reference := self readReferenceNumber.
				reference ifNil: [ self syntaxErrorCode: 157 ].
				reference = 0 ifTrue: [ self syntaxErrorCode: 115 ].
				self registerReference: reference ].
	^ subroutine
		  ifTrue: [ PCRE2SubroutineNode new reference: reference ]
		  ifFalse: [
				  PCRE2BackreferenceNode new
					  reference: (self noteBackreference: reference);
					  options: options;
					  extraOptions: extraOptions ]
]

{ #category : 'validation' }
PCRE2PatternParser >> registerRecursionCondition: name at: index [

	| offset |
	offset := self codeUnitOffsetAt: index.
	references add: [
			(names includes: name) ifFalse: [
					| number |
					number := 0.
					2 to: name size do: [ :digit |
							number := number * 10 + (name at: digit) asciiValue - $0 asciiValue.
							number > 65535 ifTrue: [ self syntaxErrorCode: 161 atCodeUnit: (self codeUnitOffsetAt: index + digit - 1) ] ].
					number > captureCount ifTrue: [ self syntaxErrorCode: 115 atCodeUnit: offset ] ] ]
]

{ #category : 'validation' }
PCRE2PatternParser >> registerReference: reference [

	^ self registerReference: reference at: position
]

{ #category : 'validation' }
PCRE2PatternParser >> registerReference: reference at: index [

	| offset |
	offset := self codeUnitOffsetAt: index.
	references add: [
			(reference isInteger and: [ reference > 65535 ]) ifTrue: [ self syntaxErrorCode: 161 atCodeUnit: offset ].
			(reference isInteger
				 ifTrue: [ reference < 0 or: [ reference > captureCount ] ]
				 ifFalse: [ (names includes: reference) not ]) ifTrue: [ self syntaxErrorCode: 115 atCodeUnit: offset ] ].
	^ reference
]

{ #category : 'signalling' }
PCRE2PatternParser >> rejectVerbName: name [
	"PCRE2 consumes the equals sign of a start directive it knows before blaming the verb."

	(self peek = $= and: [ self class limitDirectives includesKey: name ]) ifTrue: [ self next ].
	self syntaxErrorCode: 160
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
PCRE2PatternParser >> singleNewlineCode [
	"The one byte this pattern's newline convention ends a line with, or nil when a written matcher cannot decide a line end by reading one byte."

	^ newlineConvention singleTerminator
]

{ #category : 'scanning' }
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

{ #category : 'scanning' }
PCRE2PatternParser >> skipIgnored [

	| extended consumed |
	extended := (options bitAnd: (PCRE2 extended bitOr: PCRE2 extendedMore)) ~= 0.
	[
		consumed := false.
		(pattern findString: '\Q\E' startingAt: position) = position ifTrue: [
				position := position + 4.
				consumed := true ].
		(pattern findString: '\E' startingAt: position) = position ifTrue: [
				position := position + 2.
				consumed := true ].
		(pattern findString: '(?#' startingAt: position) = position ifTrue: [
				position := position + 3.
				self readUntil: $) errorCode: 118.
				consumed := true ].
		(extended and: [
			 self atEnd not and: [ (#( 9 10 11 12 13 32 133 8206 8207 8232 8233 ) includes: self peek asInteger) or: [ self peek = $# ] ] ])
			ifTrue: [
					self peek = $#
						ifTrue: [ self skipPatternComment ]
						ifFalse: [ position := position + 1 ].
					consumed := true ].
		consumed ] whileTrue
]

{ #category : 'scanning' }
PCRE2PatternParser >> skipPatternComment [

	| length |
	[ self atEnd ] whileFalse: [
			length := newlineConvention lengthAt: position in: pattern.
			length > 0 ifTrue: [
					position := position + length.
					^ self ].
			position := position + 1 ]
]

{ #category : 'scanning' }
PCRE2PatternParser >> skipQuantifierSpaces [

	[ self peek = Character space or: [ self peek = Character tab ] ] whileTrue: [ position := position + 1 ]
]

{ #category : 'parsing' }
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
	limitNames := self class limitDirectives.
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

{ #category : 'parsing - optimization' }
PCRE2PatternParser >> startLine [
	"Whether every branch starts at a line start, so that matching may jump from one line to the next."

	^ startLine
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> startOfLinePredicate [
	"^: the start of the subject unless PCRE2_NOTBOL applies, and after any line terminator in multiline mode."

	| convention multiline altCircumflex |
	convention := newlineConvention.
	multiline := (options bitAnd: PCRE2 multiline) ~= 0.
	altCircumflex := (options bitAnd: PCRE2 altCircumflex) ~= 0.
	^ [ :engine :state |
		  | index |
		  index := state position.
		  (index = 0 and: [ (engine matchOptions bitAnd: PCRE2 notBOL) = 0 ]) or: [
				  multiline and: [
					  (index < engine subject size or: [ altCircumflex ]) and: [ (convention lengthEndingAt: index in: engine subject) > 0 ] ] ] ]
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> subroutineNode: reference [

	^ self subroutineNode: reference closingErrorCode: 114
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> subroutineNode: reference closingErrorCode: errorCode [

	| retained |
	retained := self peek = $(
		            ifTrue: [ self captureReferenceList ]
		            ifFalse: [ #(  ) ].
	self expect: $) errorCode: errorCode.
	^ PCRE2SubroutineNode new
		  reference: reference;
		  retainedGroups: retained
]

{ #category : 'signalling' }
PCRE2PatternParser >> syntaxError: message [

	| offset |
	offset := patternOffsets at: (position min: pattern size + 1).
	PCRE2CompileError signal: message in: input at: offset
]

{ #category : 'signalling' }
PCRE2PatternParser >> syntaxError: message atCodeUnit: offset [

	PCRE2CompileError signal: message in: input at: offset
]

{ #category : 'signalling' }
PCRE2PatternParser >> syntaxErrorCode: errorCode [
	"Signal the PCRE2 compile error this code names, at the current position."

	self syntaxError: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'signalling' }
PCRE2PatternParser >> syntaxErrorCode: errorCode atCodeUnit: offset [
	"Signal the PCRE2 compile error this code names, at a known code-unit offset."

	self syntaxError: (PCRE2 translateErrorCode: errorCode) atCodeUnit: offset
]

{ #category : 'signalling' }
PCRE2PatternParser >> unexpectedClassExpression [

	self peek = $\ ifTrue: [
			self classOperand.
			self syntaxErrorCode: 213 ].
	(self peek = $[ and: [ position < pattern size and: [ (pattern at: position + 1) = $: ] ]) ifTrue: [
			self classElement.
			self syntaxErrorCode: 213 ].
	self next.
	self syntaxErrorCode: 213
]

{ #category : 'parsing - escapes' }
PCRE2PatternParser >> unicodeEscape [

	| digits start code |
	start := position.
	(self peek = (Character value: 123) and: [ (extraOptions bitAnd: PCRE2 extraAltBsux) ~= 0 ])
		ifTrue: [
				self next.
				digits := self readUntil: $} errorCode: 167 ]
		ifFalse: [
				digits := String streamContents: [ :stream |
					          4 timesRepeat: [
						          (self peek isNotNil and: [ self peek digitValue between: 0 and: 15 ]) ifTrue: [ stream nextPut: self next ] ] ].
				digits size < 4 ifTrue: [
						position := start.
						^ self literal: $u ] ].
	digits isEmpty ifTrue: [ self syntaxErrorCode: 178 ].
	code := [ Integer readFrom: digits readStream base: 16 ]
		        on: Error
		        do: [ :error | self syntaxErrorCode: 178 ].
	code > 16r10FFFF ifTrue: [ self syntaxErrorCode: 134 ].
	^ self literalCodePoint: code
]

{ #category : 'signalling' }
PCRE2PatternParser >> unsupported: feature [

	PCRE2UnsupportedFeature signal: 'Pharo backend does not yet support ' , feature
]

{ #category : 'signalling' }
PCRE2PatternParser >> unterminatedClassExpressionCode [
	"PCRE2 blames the open parenthesis only while nothing at all follows it."

	^ (classExpressionDelimiter = $) and: [ position = classExpressionStart ])
		  ifTrue: [ 114 ]
		  ifFalse: [ 106 ]
]

{ #category : 'signalling' }
PCRE2PatternParser >> unterminatedUTSClassCode [
	"PCRE2 blames the extended-class bracket only once a nested class has closed inside this one."

	^ utsNestedClassClosed == true
		  ifTrue: [ 212 ]
		  ifFalse: [ 106 ]
]

{ #category : 'parsing' }
PCRE2PatternParser >> utfPattern [

	(PCRE2CodeUnitText utfErrorIn: input bytes width: codeUnitWidth) ifNotNil: [ :error |
		PCRE2CompileError signal: (PCRE2 translateErrorCode: error first) in: input at: error second ].
	^ (input readFrom: 1 to: input size) asString
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> utsClass [

	| previous |
	previous := utsNestedClassClosed.
	utsNestedClassClosed := false.
	^ [ self withExtendedClassDo: [ self parseUTSClass ] ] ensure: [ utsNestedClassClosed := previous ]
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> utsOperator [

	| end character |
	character := self peek.
	(character isNotNil and: [ '&|-~' includes: character ]) ifFalse: [ ^ nil ].
	(position < pattern size and: [ (pattern at: position + 1) = character ]) ifFalse: [ ^ nil ].
	end := position + 2.
	[ end <= pattern size and: [ (pattern at: end) = character ] ] whileTrue: [ end := end + 1 ].
	end > (position + 2) ifTrue: [ self syntaxErrorCode: 208 atCodeUnit: (self codeUnitOffsetAt: end) ].
	^ character
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> utsRangeAllowedAfter: node [

	| next |
	(self peek = $- and: [ self utsOperator isNil and: [ position < pattern size ] ]) ifFalse: [ ^ false ].
	next := pattern at: position + 1.
	(next = $] or: [ next = $[ ]) ifTrue: [ ^ false ].
	(position + 2 <= pattern size and: [ '&|~' includes: next ]) ifTrue: [ (pattern at: position + 2) = next ifTrue: [ ^ false ] ].
	^ true
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> utsSegmentAllowingClosingLiteral: allowClosing [

	| predicates first node end |
	predicates := OrderedCollection new.
	first := allowClosing.
	self skipClassIgnored.
	[ self atEnd not and: [ (self peek ~= $] or: [ first ]) and: [ self utsOperator isNil ] ] ] whileTrue: [
			node := self classElement.
			(node isKindOf: PCRE2QuotedSequenceNode) ifTrue: [
					node children ifEmpty: [ self syntaxErrorCode: self unterminatedUTSClassCode ].
					node children allButLast do: [ :quoted | predicates add: quoted predicate ].
					node := node children last ].
			(node isKindOf: PCRE2CharacterNode) ifFalse: [ self syntaxErrorCode: 107 ].
			self skipClassIgnored.
			(self utsRangeAllowedAfter: node)
				ifTrue: [
						self next.
						self skipClassIgnored.
						self peek = $]
							ifTrue: [
									predicates
										add: node predicate;
										add: (self literal: $-) predicate ]
							ifFalse: [
									node character ifNil: [ self syntaxErrorCode: 150 ].
									end := self classElementAsRangeEnd: true.
									(end isKindOf: PCRE2QuotedSequenceNode) ifTrue: [
											end children ifEmpty: [ self syntaxErrorCode: self unterminatedUTSClassCode ].
											end children allButFirst do: [ :quoted | predicates add: quoted predicate ].
											end := end children first ].
									(node character isNil or: [ end character isNil ]) ifTrue: [ self syntaxErrorCode: 150 ].
									end character ifNotNil: [
											node character > end character ifTrue: [ self syntaxErrorCode: 108 ].
											predicates add: (self rangeFrom: node character to: end character caseless: (options bitAnd: PCRE2 caseless) ~= 0) ] ] ]
				ifFalse: [ predicates add: node predicate ].
			first := false.
			self skipClassIgnored ].
	predicates ifEmpty: [
			self atEnd ifTrue: [ self syntaxErrorCode: self unterminatedUTSClassCode ].
			self utsOperator ifNotNil: [ self syntaxErrorCode: 209 atCodeUnit: (self codeUnitOffsetAt: position + 2) ].
			self syntaxErrorCode: 210 atCodeUnit: (self codeUnitOffsetAt: position + 1) ].
	^ [ :candidate | predicates anySatisfy: [ :predicate | predicate value: candidate ] ]
]

{ #category : 'validation' }
PCRE2PatternParser >> validateCaptureName: name [

	| unicode first start valid |
	start := position - name size - 1.
	name isEmpty ifTrue: [ self syntaxErrorCode: 162 atCodeUnit: (self codeUnitOffsetAt: start) ].
	unicode := (options bitAnd: PCRE2 utf) ~= 0.
	first := name first.
	(first = $_ or: [
			 unicode
				 ifTrue: [ PCRE2UnicodeData matches: 'gc:l' code: first asInteger ]
				 ifFalse: [ (first between: $A and: $Z) or: [ first between: $a and: $z ] ] ]) ifFalse: [
			self
				syntaxErrorCode: ((first between: $0 and: $9)
						 ifTrue: [ 144 ]
						 ifFalse: [ 162 ])
				atCodeUnit: (self codeUnitOffsetAt: start) ].
	name withIndexDo: [ :character :index |
			valid := character = $_ or: [
					         unicode
						         ifTrue: [
							         (PCRE2UnicodeData matches: 'gc:l' code: character asInteger) or: [
								         PCRE2UnicodeData matches: 'gc:nd' code: character asInteger ] ]
						         ifFalse: [ character asInteger < 128 and: [ character isAlphaNumeric ] ] ].
			valid ifFalse: [ self syntaxErrorCode: 142 atCodeUnit: (self codeUnitOffsetAt: start + index - 1) ] ].
	(codeUnitWidth = 8
		 ifTrue: [ name asPCRE2UTF8Input size ]
		 ifFalse: [
				 codeUnitWidth = 16
					 ifTrue: [ name asPCRE2UTF16Input size ]
					 ifFalse: [ name size ] ]) > 128 ifTrue: [ self syntaxErrorCode: 148 ]
]

{ #category : 'validation' }
PCRE2PatternParser >> validateLookaroundResetsIn: node active: enclosing [

	| active |
	active := enclosing or: [
			          ((node isKindOf: PCRE2LookaheadNode) or: [ node isKindOf: PCRE2LookbehindNode ]) and: [
				          (node isKindOf: PCRE2ScanSubstringNode) not ] ].
	(active and: [
			 (extraOptions bitAnd: PCRE2 extraAllowLookaroundBsk) = 0 and: [
				 (node isKindOf: PCRE2AssertionNode) and: [ node kind = #resetStart ] ] ]) ifTrue: [
		self syntaxError: '\K is not allowed in lookarounds (but see PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK)' ].
	(self patternChildrenOf: node) do: [ :child | self validateLookaroundResetsIn: child active: active ]
]

{ #category : 'validation' }
PCRE2PatternParser >> validateLookbehinds [

	lookbehinds do: [ :entry |
			| bounds |
			bounds := IdentityDictionary new.
			entry second do: [ :branch |
					| lengths errorOffset |
					errorOffset := lookbehindPositions at: entry first ifAbsent: [ self codeUnitOffsetAt: position ].
					(branchResetUsed = true and: [ self hasBackreferenceIn: branch ]) ifTrue: [
						self syntaxErrorCode: 125 atCodeUnit: errorOffset ].
					(self isRecursiveLength: branch visiting: IdentitySet new) ifTrue: [ self syntaxErrorCode: 125 atCodeUnit: errorOffset ].
					(branchResetUsed = true and: [ (self lookbehindBranchCount: branch upTo: 2000) > 2000 ]) ifTrue: [
						self syntaxError: 'lookbehind is too complicated' atCodeUnit: errorOffset ].
					lengths := branch lengthBoundsUsing: groups names: names visited: IdentitySet new.
					lengths second ifNil: [ self syntaxErrorCode: 125 atCodeUnit: errorOffset ].
					lengths second > 65535 ifTrue: [ self syntaxErrorCode: 187 atCodeUnit: errorOffset ].
					(lengths second > lookbehindLimit and: [ lengths first ~= lengths second ]) ifTrue: [
						self syntaxErrorCode: 200 atCodeUnit: errorOffset ].
					bounds at: branch put: lengths ].
			entry first branchBounds: bounds ]
]

{ #category : 'validation' }
PCRE2PatternParser >> validateTurkishCasing [

	(extraOptions bitAnd: PCRE2 extraTurkishCasing) = 0 ifTrue: [ ^ self ].
	(options bitAnd: PCRE2 utf | PCRE2 ucp) = 0 ifTrue: [ self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING requires UTF or UCP' ].
	(codeUnitWidth = 8 and: [ (options bitAnd: PCRE2 utf) = 0 ]) ifTrue: [
		self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING requires UTF in 8-bit mode' ].
	(extraOptions bitAnd: PCRE2 extraCaselessRestrict) ~= 0 ifTrue: [
		self syntaxError: 'PCRE2_EXTRA_TURKISH_CASING is incompatible with PCRE2_EXTRA_CASELESS_RESTRICT' ]
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> versionCondition [

	| ge major minor current requested result |
	position := position + 7.
	ge := self peek = $>.
	ge ifTrue: [ self next ].
	(self peek = $= and: [
			 self next.
			 self peek isNotNil and: [ self peek between: $0 and: $9 ] ]) ifFalse: [
			(ge not and: [ self atEnd not ]) ifTrue: [ self next ].
			self syntaxErrorCode: 179 ].
	major := self decimal.
	major > 1000 ifTrue: [ self syntaxErrorCode: 179 ].
	minor := 0.
	self peek = $. ifTrue: [
			self next.
			(self peek isNotNil and: [ self peek between: $0 and: $9 ]) ifFalse: [
					self atEnd ifFalse: [ self next ].
					self syntaxErrorCode: 179 ].
			minor := self decimal.
			minor > 1000 ifTrue: [ self syntaxErrorCode: 179 ] ].
	self peek = $) ifFalse: [
			self atEnd ifFalse: [ self next ].
			self syntaxErrorCode: 179 ].
	self next.
	current := PCRE2CompilerPharoBackend compatibleVersion.
	requested := {
		             major.
		             minor }.
	result := ge
		          ifTrue: [ current first > major or: [ current first = major and: [ current second >= minor ] ] ]
		          ifFalse: [ current = requested ].
	^ result
]

{ #category : 'parsing - groups' }
PCRE2PatternParser >> versionCondition: text [

	| comparison parts requested current result |
	comparison := (text beginsWith: 'VERSION>=')
		              ifTrue: [ #greaterOrEqual ]
		              ifFalse: [ #equal ].
	parts := (text allButFirst: (comparison = #equal
			           ifTrue: [ 8 ]
			           ifFalse: [ 9 ])) findTokens: '.'.
	(parts isEmpty or: [
			 parts size > 2 or: [
				 parts anySatisfy: [ :part | part isEmpty or: [ (part allSatisfy: [ :digit | digit between: $0 and: $9 ]) not ] ] ] ])
		ifTrue: [ self syntaxError: 'invalid version condition' ].
	requested := {
		             parts first asInteger.
		             (parts size = 1
			              ifTrue: [ 0 ]
			              ifFalse: [ parts second asInteger ]) }.
	current := PCRE2CompilerPharoBackend compatibleVersion.
	result := comparison = #equal
		          ifTrue: [ current = requested ]
		          ifFalse: [
		          current first > requested first or: [ current first = requested first and: [ current second >= requested second ] ] ].
	^ result
]

{ #category : 'parsing - classes' }
PCRE2PatternParser >> withExtendedClassDo: block [

	extendedClassDepth := (extendedClassDepth ifNil: [ 0 ]) + 1.
	extendedClassDepth > 15 ifTrue: [
			extendedClassDepth := extendedClassDepth - 1.
			self syntaxErrorCode: 207 atCodeUnit: (self codeUnitOffsetAt: position - 1) ].
	^ block ensure: [ extendedClassDepth := extendedClassDepth - 1 ]
]

{ #category : 'parsing - assertions' }
PCRE2PatternParser >> wordBoundaryPredicateFor: kind [
	"\b and \B: where a word character meets something that is not one. The edges of the window count as not one, and reaching the end of the subject there is what partial matching calls a hit."

	| word wanted |
	word := self predicateFor: $w.
	wanted := kind = #wordBoundary.
	^ [ :engine :state |
		  | index size previous before after |
		  index := state position.
		  size := engine subject size.
		  index = size ifTrue: [ engine notePartial: state ].
		  previous := engine subject previousOffsetFrom: index.
		  before := previous >= 0 and: [ word value: (engine subject at: previous + 1) ].
		  after := index < size and: [ word value: (engine subject at: index + 1) ].
		  before ~= after = wanted ]
]
