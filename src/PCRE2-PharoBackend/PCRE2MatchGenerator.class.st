"
Writes a Pharo method that matches one pattern over raw bytes, or answers nil for a shape it cannot write or one that grows past sizeLimit. Each node writes itself through writeInto:at:then:, the block writing what follows inside it, so the match lives in locals and on the Smalltalk stack rather than in copied match states. The method hands the match back to the engine at the first byte over 127 and no test it writes holds inside a character; its source is written without layout, and the compiled method keeps no source and is installed in no class.
"
Class {
	#name : 'PCRE2MatchGenerator',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'locals',
		'counter',
		'captures',
		'guard',
		'failed',
		'tables',
		'lineStart'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'generating' }
PCRE2MatchGenerator class >> sourceFor: aNode captures: anInteger lineStart: aCode [
	"The source of a method matching this pattern over bytes, or nil for a shape this cannot write. A code is the byte ending a line, for a pattern that can only match at the start of one."

	^ self new
		  captureCount: anInteger;
		  lineStart: aCode;
		  sourceFor: aNode
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureCount: anInteger [

	captures := anInteger
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureEnd: index [

	^ 'c' , index printString , 'b'
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureStart: index [

	^ 'c' , index printString , 'a'
]

{ #category : 'generating' }
PCRE2MatchGenerator >> conditionFor: aTest at: position [
	"One position assertion as an expression over bytes. Each refuses a byte over 127 or holds only where a character begins, so none lets a match start inside a character."

	| kind code |
	kind := aTest first.
	kind = #atStart ifTrue: [ ^ position , ' == 0' ].
	kind = #atEnd ifTrue: [ ^ position , ' == size' ].
	code := aTest second printString.
	kind = #afterTerminator ifTrue: [
			^ String streamContents: [ :out |
					  out
						  nextPut: $(;
						  nextPutAll: position;
						  nextPutAll: ' == 0 or: [ '.
					  aTest third ifFalse: [
							  out
								  nextPutAll: position;
								  nextPutAll: ' < size and: [ ' ].
					  out
						  nextPutAll: '(bytes byteAt: ';
						  nextPutAll: position;
						  nextPutAll: ') == ';
						  nextPutAll: code.
					  aTest third ifFalse: [ out nextPutAll: ' ]' ].
					  out nextPutAll: ' ])' ] ].
	kind = #beforeTerminator ifTrue: [ ^ '(' , position , ' == size or: [ (bytes byteAt: ' , position , ' + 1) == ' , code , ' ])' ].
	kind = #beforeFinalTerminator ifTrue: [
		^ '(' , position , ' == size or: [ ' , position , ' + 1 == size and: [ (bytes byteAt: size) == ' , code , ' ] ])' ].
	^ nil
]

{ #category : 'generating' }
PCRE2MatchGenerator >> exhausted [
	"Whether to write no more: a shape was refused, or the method is too big to be worth compiling."

	^ failed or: [ stream position > self sizeLimit or: [ locals size + tables size > self localLimit ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> fallbackConditionWithMaximum: maximum counter: count position: run [
	"Whether the run stopped at a byte over 127, which hands the match back to the engine."

	| test |
	test := run , ' < size and: [ (bytes byteAt: ' , run , ' + 1) > 127 ]'.
	^ maximum ifNil: [ test ] ifNotNil: [ count , ' < ' , maximum printString , ' and: [ ' , test , ' ]' ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> lineStart: aCode [

	lineStart := aCode
]

{ #category : 'generating' }
PCRE2MatchGenerator >> localLimit [
	"A method has room for 64 locals, arguments included."

	^ 50
]

{ #category : 'generating' }
PCRE2MatchGenerator >> lookupFor: ranges [
	"The local holding a lookup table for these ranges, shared by every item accepting the same codes. Its first entry stands for no character, which a word boundary reads."

	| key name |
	key := ByteArray new: 129.
	ranges do: [ :range | range first to: range second do: [ :code | key at: code + 2 put: 1 ] ].
	tables do: [ :each | each value = key ifTrue: [ ^ each key ] ].
	name := self nextLabel: 't'.
	tables add: name -> key.
	^ name
]

{ #category : 'generating' }
PCRE2MatchGenerator >> nextLabel: aPrefix [
	"A fresh name, declared where the caller says."

	counter := counter + 1.
	^ aPrefix , counter printString
]

{ #category : 'generating' }
PCRE2MatchGenerator >> nextName: aPrefix [
	"A fresh local of the method."

	| name |
	name := self nextLabel: aPrefix.
	locals add: name.
	^ name
]

{ #category : 'generating' }
PCRE2MatchGenerator >> offsetAfter: position [
	"The position one character on, as one addition to the same local: a run of single characters would otherwise want a local each."

	| index tail |
	index := position indexOfSubCollection: ' + '.
	tail := index = 0
		        ifTrue: [ '' ]
		        ifFalse: [ position allButFirst: index + 2 ].
	(tail isNotEmpty and: [ tail allSatisfy: [ :each | each isDigit ] ]) ifFalse: [ ^ position , ' + 1' ].
	^ (position first: index + 2) , (tail asInteger + 1) printString
]

{ #category : 'generating' }
PCRE2MatchGenerator >> rangesOf: table [
	"The codes under 128 the table accepts, as ranges. A written matcher never judges a higher byte: it hands the match back to the engine."

	| ranges low |
	ranges := OrderedCollection new.
	0 to: 128 do: [ :code |
			(code < 128 and: [ (table at: code + 1) == 1 ])
				ifTrue: [ low ifNil: [ low := code ] ]
				ifFalse: [
						low ifNotNil: [
								ranges add: {
										low.
										(code - 1) }.
								low := nil ] ] ].
	^ ranges asArray
]

{ #category : 'generating' }
PCRE2MatchGenerator >> refuse [
	"The shape is one this cannot write; what was written is thrown away."

	failed := true.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> scanConditionOf: ranges maximum: maximum counter: count position: run [
	"The condition of the loop counting off one item's characters."

	| test |
	test := run , ' < size and: [ (byte := bytes byteAt: ' , run , ' + 1) < 128 and: [ ' , (self testFor: ranges on: 'byte') , ' ] ]'.
	^ maximum ifNil: [ test ] ifNotNil: [ count , ' < ' , maximum printString , ' and: [ ' , test , ' ]' ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sizeLimit [
	"How much source a pattern may be written as. What follows an alternation is written into each branch, so a few can grow a pattern far past its own length."

	^ 24000
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sourceAround: aString stops: stops [
	"The method around the body: the search over start positions, the tables and the locals. A pattern that can only begin a line skips the positions inside one, except the one asked for. A body that always answers needs no next start."

	^ String streamContents: [ :out |
			  out nextPutAll: 'matchFrom: begin to: last in: bytes into: offsets | size start byte'.
			  tables do: [ :each |
					  out
						  space;
						  nextPutAll: each key ].
			  locals do: [ :name |
					  out
						  space;
						  nextPutAll: name ].
			  out nextPutAll: ' | size := bytes size. start := begin. '.
			  tables do: [ :each |
					  out
						  nextPutAll: each key;
						  nextPutAll: ' := ';
						  print: each value;
						  nextPutAll: '. ' ].
			  1 to: captures do: [ :index |
					  out
						  nextPutAll: (self captureStart: index);
						  nextPutAll: ' := -1. ';
						  nextPutAll: (self captureEnd: index);
						  nextPutAll: ' := -1. ' ].
			  out
				  nextPutAll: '[ start <= last ] whileTrue: [';
				  nextPutAll: aString.
			  stops ifFalse: [
					  out nextPutAll: '. start := start + 1'.
					  lineStart ifNotNil: [
							  out
								  nextPutAll: '. [ start < size and: [ (bytes byteAt: start) ~~ ';
								  print: lineStart;
								  nextPutAll: ' ] ] whileTrue: [ start := start + 1 ]' ] ].
			  out nextPutAll: ' ]. ^ false' ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sourceFor: aNode [
	"The whole method, or nil for a shape this cannot write. The source is compiled and dropped, so it is written with no layout."

	| body stops |
	failed := false.
	counter := 0.
	locals := OrderedCollection new.
	tables := OrderedCollection new.
	1 to: captures do: [ :index |
			locals
				add: (self captureStart: index);
				add: (self captureEnd: index) ].
	stream := body := (String new: 1024) writeStream.
	stops := aNode writeInto: self at: 'start' then: [ :position | self writeSuccessAt: position ].
	failed ifTrue: [ ^ nil ].
	^ self sourceAround: body contents stops: stops
]

{ #category : 'generating' }
PCRE2MatchGenerator >> testFor: ranges on: variable [
	"Whether the byte in the variable is accepted: one or two ranges are compared, more are looked up in a table. It compares small integers with ==, and is parenthesised, since it always receives another keyword message."

	(ranges isEmpty or: [ ranges size > 2 ]) ifTrue: [ ^ '((' , (self lookupFor: ranges) , ' at: ' , variable , ' + 2) == 1)' ].
	^ String streamContents: [ :out |
			  out nextPut: $(.
			  ranges doWithIndex: [ :range :index |
					  index > 1 ifTrue: [ out nextPutAll: ' or: [ ' ].
					  range first = range second
						  ifTrue: [
								  out
									  nextPutAll: variable;
									  nextPutAll: ' == ';
									  print: range first ]
						  ifFalse: [
								  out
									  nextPut: $(;
									  nextPutAll: variable;
									  nextPutAll: ' >= ';
									  print: range first;
									  nextPutAll: ' and: [ ';
									  nextPutAll: variable;
									  nextPutAll: ' <= ';
									  print: range second;
									  nextPutAll: ' ])' ] ].
			  ranges size - 1 timesRepeat: [ out nextPutAll: ' ]' ].
			  out nextPut: $) ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> turnLimit [
	"How many turns of a repetition, each a pending call, before handing the match back to the engine, which keeps its turns on the heap."

	^ 100000
]

{ #category : 'generating' }
PCRE2MatchGenerator >> unrollLimit [
	"How many turns of a repetition may be written out in full."

	^ 8
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAlternation: children at: position then: aBlock [
	"Each branch has what follows written inside it, and falls through to the next when it fails. A branch that always answers makes the rest unreachable."

	| stops |
	self exhausted ifTrue: [ ^ self refuse ].
	stops := false.
	children doWithIndex: [ :branch :index |
			(stops or: [ failed ]) ifFalse: [
					index > 1 ifTrue: [ stream nextPutAll: '. ' ].
					stops := index = 1
						         ifTrue: [ branch writeInto: self at: position then: aBlock ]
						         ifFalse: [ self writeGuarded: [ :where | branch writeInto: self at: where then: aBlock ] at: position ] ] ].
	^ stops
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAssertion: aTest at: position then: aBlock [
	"A position assertion reads nothing: what follows is written inside its test."

	| condition |
	self exhausted ifTrue: [ ^ self refuse ].
	aTest ifNil: [ ^ self refuse ].
	aTest first = #wordBoundary ifTrue: [ ^ self writeWordBoundary: aTest at: position then: aBlock ].
	condition := (self conditionFor: aTest at: position) ifNil: [ ^ self refuse ].
	stream
		nextPutAll: condition;
		nextPutAll: ' ifTrue: ['.
	aBlock value: position.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAtomic: aNode at: position then: aBlock [
	"An atomic group keeps the first way it found of matching: a flag says it found one, and the body reads it."

	| flag held outer stops |
	self exhausted ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	held := self nextName: 'h'.
	stream
		nextPutAll: flag;
		nextPutAll: ' := false. ';
		nextPutAll: held;
		nextPutAll: ' := 0. '.
	outer := guard.
	guard := flag.
	stops := aNode writeInto: self at: position then: [ :next |
			         stream
				         nextPutAll: flag;
				         nextPutAll: ' := true. ';
				         nextPutAll: held;
				         nextPutAll: ' := ';
				         nextPutAll: next.
			         false ].
	guard := outer.
	stops ifTrue: [ ^ self refuse ].
	stream
		nextPutAll: '. ';
		nextPutAll: flag;
		nextPutAll: ' ifTrue: ['.
	aBlock value: held.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeBackreference: index at: position then: aBlock [
	"It reads the subject where the group caught it and here, as bytes: a byte over 127 on either side hands the match back to the engine."

	| span same step hold start |
	self exhausted ifTrue: [ ^ self refuse ].
	(index isNil or: [ index > captures ]) ifTrue: [ ^ self refuse ].
	start := self captureStart: index.
	span := self nextName: 'l'.
	same := self nextName: 'k'.
	step := self nextName: 'i'.
	hold := self nextName: 'p'.
	stream
		nextPutAll: span;
		nextPutAll: ' := ';
		nextPutAll: (self captureEnd: index);
		nextPutAll: ' - ';
		nextPutAll: start;
		nextPutAll: '. (';
		nextPutAll: start;
		nextPutAll: ' >= 0 and: [ ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: span;
		nextPutAll: ' <= size ]) ifTrue: [';
		nextPutAll: same;
		nextPutAll: ' := true. ';
		nextPutAll: step;
		nextPutAll: ' := 0. [ ';
		nextPutAll: same;
		nextPutAll: ' and: [ ';
		nextPutAll: step;
		nextPutAll: ' < ';
		nextPutAll: span;
		nextPutAll: ' ] ] whileTrue: [byte := bytes byteAt: ';
		nextPutAll: start;
		nextPutAll: ' + ';
		nextPutAll: step;
		nextPutAll: ' + 1. byte > 127 ifTrue: [ ^ nil ]. ';
		nextPutAll: same;
		nextPutAll: ' := byte == (bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: step;
		nextPutAll: ' + 1). ';
		nextPutAll: step;
		nextPutAll: ' := ';
		nextPutAll: step;
		nextPutAll: ' + 1 ]. ';
		nextPutAll: same;
		nextPutAll: ' ifTrue: [';
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: span;
		nextPutAll: '. '.
	aBlock value: hold.
	stream nextPutAll: ' ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeCapture: aNode at: position then: aBlock [
	"A group sets its offsets before what follows and puts the previous ones back after, so a branch that did not survive leaves nothing caught. Inside a lookaround or an atomic group, which keep no attempt here, it is left to the engine."

	| start finish index heldStart heldEnd |
	self exhausted ifTrue: [ ^ self refuse ].
	index := aNode index.
	(index > captures or: [ guard isNotNil ]) ifTrue: [ ^ self refuse ].
	start := self captureStart: index.
	finish := self captureEnd: index.
	heldStart := self nextName: 'r'.
	heldEnd := self nextName: 's'.
	^ aNode child writeInto: self at: position then: [ :next |
			  stream
				  nextPutAll: heldStart;
				  nextPutAll: ' := ';
				  nextPutAll: start;
				  nextPutAll: '. ';
				  nextPutAll: heldEnd;
				  nextPutAll: ' := ';
				  nextPutAll: finish;
				  nextPutAll: '. ';
				  nextPutAll: start;
				  nextPutAll: ' := ';
				  nextPutAll: position;
				  nextPutAll: '. ';
				  nextPutAll: finish;
				  nextPutAll: ' := ';
				  nextPutAll: next;
				  nextPutAll: '. '.
			  (aBlock value: next) or: [
					  stream
						  nextPutAll: '. ';
						  nextPutAll: start;
						  nextPutAll: ' := ';
						  nextPutAll: heldStart;
						  nextPutAll: '. ';
						  nextPutAll: finish;
						  nextPutAll: ' := ';
						  nextPutAll: heldEnd.
					  false ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeConditional: aNode at: position then: aBlock [
	"A condition settled when the pattern was read leaves one branch; one asking whether a group took part tests its offset, with what follows written into both branches."

	| test taken missed |
	self exhausted ifTrue: [ ^ self refuse ].
	test := aNode byteCondition ifNil: [ ^ self refuse ].
	test first = #never ifTrue: [ ^ aNode elseBranch writeInto: self at: position then: aBlock ].
	test first = #always ifTrue: [ ^ aNode thenBranch writeInto: self at: position then: aBlock ].
	test second > captures ifTrue: [ ^ self refuse ].
	stream
		nextPutAll: (self captureEnd: test second);
		nextPutAll: ' >= 0 ifTrue: ['.
	taken := aNode thenBranch writeInto: self at: position then: aBlock.
	stream nextPutAll: ' ] ifFalse: ['.
	missed := aNode elseBranch writeInto: self at: position then: aBlock.
	stream nextPutAll: ' ]'.
	^ taken and: [ missed ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeCopy: ordinal of: aNode at: position then: aBlock [
	"One turn of a repetition written out: the item again and, once enough turns are taken, what follows without it. Greedy tries the longer way first, lazy the shorter."

	| enough next |
	self exhausted ifTrue: [ ^ self refuse ].
	enough := ordinal > aNode minimum.
	ordinal > aNode maximum ifTrue: [
			^ enough
				  ifTrue: [ aBlock value: position ]
				  ifFalse: [ self refuse ] ].
	next := [ :where |
		        self
			        writeCopy: ordinal + 1
			        of: aNode
			        at: where
			        then: aBlock ].
	enough ifFalse: [ ^ aNode child writeInto: self at: position then: next ].
	aNode greedy ifFalse: [
			(aBlock value: position) ifTrue: [ ^ true ].
			stream nextPutAll: '. '.
			^ self writeGuarded: [ :where | aNode child writeInto: self at: where then: next ] at: position ].
	(aNode child writeInto: self at: position then: next) ifTrue: [ ^ true ].
	stream nextPutAll: '. '.
	^ self writeGuarded: aBlock at: position
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeGreedyRun: aNode at: position then: aBlock [
	"A greedy run of one character: counted off at its longest, then given back one character a turn. The count comes down before what follows, the last thing the turn does."

	| names run count hold |
	names := self writeRunUpTo: aNode maximum ranges: (self rangesOf: aNode child asciiTable) from: position.
	run := names first.
	count := names second.
	hold := self nextName: 'p'.
	stream nextPutAll: '[ '.
	guard ifNotNil: [
			stream
				nextPutAll: guard;
				nextPutAll: ' not and: [ ' ].
	stream
		nextPutAll: count;
		nextPutAll: ' >= ';
		print: aNode minimum.
	guard ifNotNil: [ stream nextPutAll: ' ]' ].
	stream
		nextPutAll: ' ] whileTrue: [';
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: '. ';
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: ' - 1. ';
		nextPutAll: count;
		nextPutAll: ' := ';
		nextPutAll: count;
		nextPutAll: ' - 1. '.
	aBlock value: hold.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeGuarded: aBlock at: position [
	"A second way of matching, which an assertion or atomic group that found what it wanted does not try."

	guard ifNil: [ ^ aBlock value: position ].
	stream
		nextPutAll: guard;
		nextPutAll: ' ifFalse: ['.
	aBlock value: position.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLazyRun: aNode at: position then: aBlock [
	"A lazy run of one character: counted off to its minimum, then lengthened by one character a turn."

	| ranges names run count hold more |
	ranges := self rangesOf: aNode child asciiTable.
	names := self writeRunUpTo: aNode minimum ranges: ranges from: position.
	run := names first.
	count := names second.
	hold := self nextName: 'p'.
	more := self nextName: 'm'.
	stream
		nextPutAll: count;
		nextPutAll: ' >= ';
		print: aNode minimum;
		nextPutAll: ' ifTrue: [';
		nextPutAll: more;
		nextPutAll: ' := true. [ ';
		nextPutAll: more.
	guard ifNotNil: [
			stream
				nextPutAll: ' and: [ ';
				nextPutAll: guard;
				nextPutAll: ' not ]' ].
	stream
		nextPutAll: ' ] whileTrue: [';
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: '. ';
		nextPutAll: more;
		nextPutAll: ' := ';
		nextPutAll: (self
				 scanConditionOf: ranges
				 maximum: aNode maximum
				 counter: count
				 position: run);
		nextPutAll: '. ';
		nextPutAll: more;
		nextPutAll: ' ifTrue: [ ';
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: ' + 1. ';
		nextPutAll: count;
		nextPutAll: ' := ';
		nextPutAll: count;
		nextPutAll: ' + 1 ]. '.
	aBlock value: hold.
	stream
		nextPutAll: ' ]. (';
		nextPutAll: (self fallbackConditionWithMaximum: aNode maximum counter: count position: run);
		nextPutAll: ') ifTrue: [ ^ nil ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLookahead: aNode at: position then: aBlock [
	"A lookahead reads ahead without keeping what it read. A flag says its body found what it wanted, which also stops the body."

	| flag outer stops |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode atomic = false ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	stream
		nextPutAll: flag;
		nextPutAll: ' := false. '.
	outer := guard.
	guard := flag.
	stops := aNode child writeInto: self at: position then: [ :next |
			         stream
				         nextPutAll: flag;
				         nextPutAll: ' := true'.
			         false ].
	guard := outer.
	stops ifTrue: [ ^ self refuse ].
	stream
		nextPutAll: '. ';
		nextPutAll: flag;
		nextPutAll: (aNode positive
				 ifTrue: [ ' ifTrue: [' ]
				 ifFalse: [ ' ifFalse: [' ]).
	aBlock value: position.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLookbehind: aNode at: position then: aBlock [
	"A lookbehind reads the characters before the position. Only branches of a fixed length are written: where they begin is then known, and one beginning inside a character reads a byte over 127 and hands the match back."

	| flag base outer |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode atomic = false ifTrue: [ ^ self refuse ].
	(aNode branches anySatisfy: [ :branch |
			 | span |
			 span := aNode maximumLengthFor: branch.
			 span isNil or: [ span ~= (aNode minimumLengthFor: branch) ] ]) ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	base := self nextName: 'b'.
	stream
		nextPutAll: flag;
		nextPutAll: ' := false. '.
	outer := guard.
	guard := flag.
	aNode branches do: [ :branch |
			stream
				nextPutAll: flag;
				nextPutAll: ' ifFalse: [';
				nextPutAll: base;
				nextPutAll: ' := ';
				nextPutAll: position;
				nextPutAll: ' - ';
				print: (aNode minimumLengthFor: branch);
				nextPutAll: '. ';
				nextPutAll: base;
				nextPutAll: ' >= 0 ifTrue: ['.
			branch writeInto: self at: base then: [ :next |
					stream
						nextPutAll: flag;
						nextPutAll: ' := true'.
					false ].
			stream nextPutAll: ' ] ]. ' ].
	guard := outer.
	failed ifTrue: [ ^ false ].
	stream
		nextPutAll: flag;
		nextPutAll: (aNode positive
				 ifTrue: [ ' ifTrue: [' ]
				 ifFalse: [ ' ifFalse: [' ]).
	aBlock value: position.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writePossessiveRepeat: aNode at: position then: aBlock [
	"One character repeated keeps its run by having no loop to give any back; anything else is a repetition inside an atomic group."

	self exhausted ifTrue: [ ^ self refuse ].
	aNode maximum = 0 ifTrue: [ ^ aBlock value: position ].
	^ aNode child asciiTable
		  ifNil: [ self writeAtomic: aNode at: position then: aBlock ]
		  ifNotNil: [ self writePossessiveRun: aNode at: position then: aBlock ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writePossessiveRun: aNode at: position then: aBlock [
	"A possessive run of one character: counted off at its longest, with nothing to give back."

	| names hold |
	names := self writeRunUpTo: aNode maximum ranges: (self rangesOf: aNode child asciiTable) from: position.
	hold := self nextName: 'p'.
	stream
		nextPutAll: names second;
		nextPutAll: ' >= ';
		print: aNode minimum;
		nextPutAll: ' ifTrue: [';
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: names first;
		nextPutAll: '. '.
	aBlock value: hold.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRecursiveRepeat: aNode at: position then: aBlock [
	"A repetition with no bound, or too many turns to write out, is a block calling itself, one turn a call, so that a turn can be given back. It declares the locals of the body, so each turn has its own. Only a body that always reads a character is written: a turn reading nothing would never end."

	| name count param mark held body inner turn rest |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode child minimumLength < 1 ifTrue: [ ^ self refuse ].
	name := self nextName: 'g'.
	count := self nextName: 'n'.
	param := self nextLabel: 'p'.
	turn := [ :where |
		        aNode maximum ifNotNil: [ :maximum |
				        stream
					        nextPutAll: count;
					        nextPutAll: ' < ';
					        print: maximum;
					        nextPutAll: ' ifTrue: [' ].
		        aNode child writeInto: self at: where then: [ :next |
				        stream
					        nextPutAll: count;
					        nextPutAll: ' := ';
					        nextPutAll: count;
					        nextPutAll: ' + 1. ';
					        nextPutAll: name;
					        nextPutAll: ' value: ';
					        nextPutAll: next;
					        nextPutAll: '. ';
					        nextPutAll: count;
					        nextPutAll: ' := ';
					        nextPutAll: count;
					        nextPutAll: ' - 1'.
				        false ].
		        aNode maximum ifNotNil: [ stream nextPutAll: ' ]' ].
		        false ].
	rest := [ :where |
		        stream
			        nextPutAll: count;
			        nextPutAll: ' >= ';
			        print: aNode minimum;
			        nextPutAll: ' ifTrue: ['.
		        aBlock value: where.
		        stream nextPutAll: ' ]'.
		        false ].
	mark := locals size.
	held := stream.
	stream := body := (String new: 256) writeStream.
	(aNode greedy
		 ifTrue: [
				 {
					 turn.
					 rest } ]
		 ifFalse: [
				 {
					 rest.
					 turn } ]) do: [ :each | self writeGuarded: each at: param ] separatedBy: [ stream nextPutAll: '. ' ].
	stream := held.
	inner := locals allButFirst: mark.
	locals := locals first: mark.
	failed ifTrue: [ ^ false ].
	stream
		nextPutAll: count;
		nextPutAll: ' := 0. ';
		nextPutAll: name;
		nextPutAll: ' := [ :';
		nextPutAll: param;
		nextPutAll: ' | '.
	inner ifNotEmpty: [
			stream nextPut: $|.
			inner do: [ :each |
					stream
						space;
						nextPutAll: each ].
			stream nextPutAll: ' | ' ].
	stream
		nextPutAll: count;
		nextPutAll: ' > ';
		print: self turnLimit;
		nextPutAll: ' ifTrue: [ ^ nil ]. ';
		nextPutAll: body contents;
		nextPutAll: ' ]. ';
		nextPutAll: name;
		nextPutAll: ' value: ';
		nextPutAll: position.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRepeat: aNode at: position then: aBlock [
	"One character repeated is counted off in a loop; anything else is written out turn by turn."

	self exhausted ifTrue: [ ^ self refuse ].
	aNode maximum = 0 ifTrue: [ ^ aBlock value: position ].
	aNode child asciiTable ifNil: [ ^ self writeUnrolledRepeat: aNode at: position then: aBlock ].
	^ aNode greedy
		  ifTrue: [ self writeGreedyRun: aNode at: position then: aBlock ]
		  ifFalse: [ self writeLazyRun: aNode at: position then: aBlock ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRunUpTo: maximum ranges: ranges from: position [
	"Count off a run of one character, at most maximum, and answer the names of where it ended and of its length. A run stopped by a byte over 127 hands the match back to the engine."

	| run count |
	run := self nextName: 'q'.
	count := self nextName: 'n'.
	stream
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: '. ';
		nextPutAll: count;
		nextPutAll: ' := 0. [ ';
		nextPutAll: (self
				 scanConditionOf: ranges
				 maximum: maximum
				 counter: count
				 position: run);
		nextPutAll: ' ] whileTrue: [';
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: ' + 1. ';
		nextPutAll: count;
		nextPutAll: ' := ';
		nextPutAll: count;
		nextPutAll: ' + 1 ]. (';
		nextPutAll: (self fallbackConditionWithMaximum: maximum counter: count position: run);
		nextPutAll: ') ifTrue: [ ^ nil ]. '.
	^ Array with: run with: count
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSequence: children at: position then: aBlock [
	"Each item is written inside the one before it, so the Smalltalk stack carries the backtracking."

	| continuation |
	continuation := aBlock.
	children reverseDo: [ :child |
			| rest |
			rest := continuation.
			continuation := [ :where | child writeInto: self at: where then: rest ] ].
	^ continuation value: position
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSingle: table at: position then: aBlock [
	"One character that is not repeated: a test, with the rest written inside it."

	self exhausted ifTrue: [ ^ self refuse ].
	stream
		nextPutAll: position;
		nextPutAll: ' < size ifTrue: [byte := bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + 1. byte > 127 ifTrue: [ ^ nil ]. ';
		nextPutAll: (self testFor: (self rangesOf: table) on: 'byte');
		nextPutAll: ' ifTrue: ['.
	aBlock value: (self offsetAfter: position).
	stream nextPutAll: ' ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSuccessAt: position [
	"The match is found: record where it runs and what each group caught, and answer."

	stream
		nextPutAll: 'offsets at: 1 put: start. offsets at: 2 put: ';
		nextPutAll: position;
		nextPutAll: '. '.
	1 to: captures do: [ :index |
			stream
				nextPutAll: 'offsets at: ';
				print: index * 2 + 1;
				nextPutAll: ' put: ';
				nextPutAll: (self captureStart: index);
				nextPutAll: '. offsets at: ';
				print: index * 2 + 2;
				nextPutAll: ' put: ';
				nextPutAll: (self captureEnd: index);
				nextPutAll: '. ' ].
	stream nextPutAll: '^ true'.
	^ true
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeUnrolledRepeat: aNode at: position then: aBlock [
	"A repetition of more than one character is written out once a turn while the turns are few, and as a block calling itself beyond that."

	| maximum |
	maximum := aNode maximum.
	(maximum isNil or: [ maximum > self unrollLimit or: [ maximum - aNode minimum > 2 ] ]) ifTrue: [
		^ self writeRecursiveRepeat: aNode at: position then: aBlock ].
	aNode child minimumLength < 1 ifTrue: [ ^ self refuse ].
	^ self
		  writeCopy: 1
		  of: aNode
		  at: position
		  then: aBlock
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeWordBoundary: aTest at: position then: aBlock [
	"It reads the characters on both sides, handing the match back when either is a byte over 127. No character reads as -1, which the first table entry stands for."

	| ranges before after |
	ranges := self rangesOf: aTest third.
	before := self nextName: 'w'.
	after := self nextName: 'x'.
	stream
		nextPutAll: before;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' > 0 ifTrue: [ bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' ] ifFalse: [ -1 ]. ';
		nextPutAll: after;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' < size ifTrue: [ bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + 1 ] ifFalse: [ -1 ]. (';
		nextPutAll: before;
		nextPutAll: ' > 127 or: [ ';
		nextPutAll: after;
		nextPutAll: ' > 127 ]) ifTrue: [ ^ nil ]. (';
		nextPutAll: (self testFor: ranges on: before);
		nextPutAll: ' ~~ ';
		nextPutAll: (self testFor: ranges on: after);
		nextPutAll: ') == ';
		print: aTest second;
		nextPutAll: ' ifTrue: ['.
	aBlock value: position.
	stream nextPutAll: ' ]'.
	^ false
]
