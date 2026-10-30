"
Writes a Pharo method that matches one pattern over raw bytes, for the patterns whose shape allows it, and answers nil for the rest.

The method it writes keeps the whole match in locals and on the Smalltalk stack: what follows an item is written inside it, so a choice is a statement that falls through to the next one and giving a character back is a loop turning once, where the engine copies a match state and queues a choice. The Cog JIT compiles such a method whether or not it is installed in a class, so the compiled pattern can carry it without adding a selector to the image.

It reads bytes, and hands the whole match back to the engine as soon as it reads one of 128 or over. Every test it writes either refuses such a byte or can only hold where a character begins, which is what keeps it from attempting a start position inside a character that the engine would never attempt.

Writing is a walk over the tree: each node writes itself through writeInto:at:indent:then:, where the block writes everything that follows it. What it can write is single characters and classes, sequences, alternation, capture groups, greedy, lazy and possessive repetition of one character, bounded repetition of anything else written out in full, atomic groups, lookahead, and the position assertions the parser could describe as a test over bytes. Anything else, and anything that grows past sizeLimit, is left to the engine.
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
	"The source of a method matching this pattern over raw bytes, or nil when the pattern is not a shape this can write. A code says the pattern can only match at the start of a line, and which byte ends one."

	^ (self new
		   captureCount: anInteger;
		   lineStart: aCode;
		   yourself) sourceFor: aNode
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureCount: anInteger [

	captures := anInteger
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureEnd: index [

	^ String streamContents: [ :out |
			  out
				  nextPut: $c;
				  print: index;
				  nextPut: $b ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> captureStart: index [

	^ String streamContents: [ :out |
			  out
				  nextPut: $c;
				  print: index;
				  nextPut: $a ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> conditionFor: aTest at: position [
	"The expression one position assertion comes down to over bytes. Each of them either refuses a byte of 128 or over or can only hold where a character begins, so none of them lets a written matcher attempt a start position inside a character."

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
	kind = #beforeTerminator ifTrue: [
			^ String streamContents: [ :out |
					  out
						  nextPut: $(;
						  nextPutAll: position;
						  nextPutAll: ' == size or: [ (bytes byteAt: ';
						  nextPutAll: position;
						  nextPutAll: ' + 1) == ';
						  nextPutAll: code;
						  nextPutAll: ' ])' ] ].
	kind = #beforeFinalTerminator ifTrue: [
			^ String streamContents: [ :out |
					  out
						  nextPut: $(;
						  nextPutAll: position;
						  nextPutAll: ' == size or: [ ';
						  nextPutAll: position;
						  nextPutAll: ' + 1 == size and: [ (bytes byteAt: size) == ';
						  nextPutAll: code;
						  nextPutAll: ' ] ])' ] ].
	^ nil
]

{ #category : 'generating' }
PCRE2MatchGenerator >> exhausted [
	"Whether nothing more should be written: either a shape was refused, or the method has grown past what is worth compiling."

	^ failed or: [ stream position > self sizeLimit or: [ locals size + tables size > self localLimit ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> fallbackConditionWithMaximum: maximum counter: count position: run [
	"Whether the run stopped at a byte this cannot judge, which sends the whole match back to the engine."

	^ String streamContents: [ :out |
			  maximum ifNotNil: [
					  out
						  nextPutAll: count;
						  nextPutAll: ' < ';
						  print: maximum;
						  nextPutAll: ' and: [ ' ].
			  out
				  nextPutAll: run;
				  nextPutAll: ' < size and: [ (bytes byteAt: ';
				  nextPutAll: run;
				  nextPutAll: ' + 1) > 127 ]'.
			  maximum ifNotNil: [ out nextPutAll: ' ]' ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> lineStart: aCode [

	lineStart := aCode
]

{ #category : 'generating' }
PCRE2MatchGenerator >> localLimit [
	"How many locals a written method may keep the match in. A method has room for sixty-four of them, arguments included, so a pattern wanting more than this is one the engine should have."

	^ 50
]

{ #category : 'generating' }
PCRE2MatchGenerator >> lookupFor: ranges [
	"The name of a local holding the lookup table for an item that accepts too many runs of codes to compare one by one. Every item in the method that accepts the same codes shares one table, and the entry before the first stands for a position with no character on that side, which a word boundary reads."

	| key found name |
	key := ByteArray new: 129.
	ranges do: [ :range | range first to: range second do: [ :code | key at: code + 2 put: 1 ] ].
	found := tables detect: [ :each | each value = key ] ifNone: [ nil ].
	found ifNotNil: [ ^ found key ].
	name := self nextLabel: 't'.
	tables add: name -> key.
	^ name
]

{ #category : 'generating' }
PCRE2MatchGenerator >> nextLabel: aPrefix [
	"A name of its own for one place in the written method, which the caller says where to declare."

	counter := counter + 1.
	^ aPrefix , counter printString
]

{ #category : 'generating' }
PCRE2MatchGenerator >> nextName: aPrefix [
	"A local of its own for one place in the written method."

	| name |
	name := self nextLabel: aPrefix.
	locals add: name.
	^ name
]

{ #category : 'generating' }
PCRE2MatchGenerator >> offsetAfter: position [
	"The position one character further on, written as one addition to the same local rather than as a local of its own. A method has room for few locals, and a run of single characters would want one each."

	| index tail |
	index := position indexOfSubCollection: ' + '.
	tail := index = 0
		        ifTrue: [ '' ]
		        ifFalse: [ position allButFirst: index + 2 ].
	(tail isNotEmpty and: [ tail allSatisfy: [ :each | each isDigit ] ]) ifFalse: [ ^ position , ' + 1' ].
	^ String streamContents: [ :out |
			  out
				  nextPutAll: (position first: index + 2);
				  print: tail asInteger + 1 ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> rangesOf: table [
	"The codes under 128 the table accepts, as ranges. Codes of 128 and over are left out on purpose: a written matcher hands the match back to the engine as soon as it reads a byte that high, so it never has to judge one."

	| ranges low |
	ranges := OrderedCollection new.
	low := nil.
	0 to: 127 do: [ :code |
			(table at: code + 1) == 1
				ifTrue: [ low ifNil: [ low := code ] ]
				ifFalse: [
						low ifNotNil: [
								ranges add: {
										low.
										(code - 1) }.
								low := nil ] ] ].
	low ifNotNil: [
			ranges add: {
					low.
					127 } ].
	^ ranges asArray
]

{ #category : 'generating' }
PCRE2MatchGenerator >> refuse [
	"The shape is one this cannot write. Everything written so far is thrown away, so there is nothing to undo."

	failed := true.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> scanConditionOf: ranges maximum: maximum counter: count position: run [
	"The condition of the loop that counts off one item's characters."

	^ String streamContents: [ :out |
			  maximum ifNotNil: [
					  out
						  nextPutAll: count;
						  nextPutAll: ' < ';
						  print: maximum;
						  nextPutAll: ' and: [ ' ].
			  out
				  nextPutAll: run;
				  nextPutAll: ' < size and: [ (byte := bytes byteAt: ';
				  nextPutAll: run;
				  nextPutAll: ' + 1) < 128 and: [ ';
				  nextPutAll: (self testFor: ranges on: 'byte');
				  nextPutAll: ' ] ]'.
			  maximum ifNotNil: [ out nextPutAll: ' ]' ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sizeLimit [
	"How much source one pattern may be written as. What follows an alternation is written into every branch of it, so a pattern with several can grow out of all proportion to its own length; past this it is left to the engine."

	^ 24000
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sourceAround: aString stops: stops [
	"The method around the written body: the search over start positions, the tables the items read, and the locals the body keeps the match in. A pattern that can only begin a line passes over the positions inside one, as the engine does, except for the position the caller asked to match from, which is always tried as it stands. A body that always answers needs no next start position, and writing one after it would be writing a statement no path reaches."

	^ String streamContents: [ :out |
			  out
				  nextPutAll: 'matchFrom: begin to: last in: bytes into: offsets';
				  lf;
				  lf;
				  tab;
				  nextPutAll: '| size start byte'.
			  tables do: [ :each |
					  out
						  nextPut: Character space;
						  nextPutAll: each key ].
			  locals do: [ :name |
					  out
						  nextPut: Character space;
						  nextPutAll: name ].
			  out
				  nextPutAll: ' |';
				  lf;
				  tab;
				  nextPutAll: 'size := bytes size.';
				  lf;
				  tab;
				  nextPutAll: 'start := begin.';
				  lf.
			  tables do: [ :each |
					  out
						  tab;
						  nextPutAll: each key;
						  nextPutAll: ' := ';
						  print: each value;
						  nextPut: $.;
						  lf ].
			  1 to: captures do: [ :index |
					  out
						  tab;
						  nextPutAll: (self captureStart: index);
						  nextPutAll: ' := -1. ';
						  nextPutAll: (self captureEnd: index);
						  nextPutAll: ' := -1.';
						  lf ].
			  out
				  tab;
				  nextPutAll: '[ start <= last ] whileTrue: [';
				  lf;
				  nextPutAll: aString.
			  stops ifFalse: [
					  out
						  nextPut: $.;
						  lf;
						  tab;
						  tab;
						  nextPutAll: 'start := start + 1'.
					  lineStart ifNotNil: [
							  out
								  nextPut: $.;
								  lf;
								  tab;
								  tab;
								  nextPutAll: '[ start < size and: [ (bytes byteAt: start) ~~ ';
								  print: lineStart;
								  nextPutAll: ' ] ] whileTrue: [ start := start + 1 ]' ] ].
			  out
				  nextPutAll: ' ].';
				  lf;
				  tab;
				  nextPutAll: '^ false' ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> sourceFor: aNode [
	"Write the whole method, or answer nil when anything in the pattern is a shape this does not know."

	| body stops |
	failed := false.
	counter := 0.
	guard := nil.
	locals := OrderedCollection new.
	tables := OrderedCollection new.
	1 to: captures do: [ :index |
			locals
				add: (self captureStart: index);
				add: (self captureEnd: index) ].
	body := (String new: 1024) writeStream.
	stream := body.
	stops := aNode
		         writeInto: self
		         at: 'start'
		         indent: 2
		         then: [ :position :level | self writeSuccessAt: position indent: level ].
	failed ifTrue: [ ^ nil ].
	^ self sourceAround: body contents stops: stops
]

{ #category : 'generating' }
PCRE2MatchGenerator >> tabs: level [

	^ String new: level withAll: Character tab
]

{ #category : 'generating' }
PCRE2MatchGenerator >> testFor: ranges on: variable [
	"An expression deciding whether the byte held in the variable is one this item accepts. One or two runs of codes are compared one by one, and anything else is looked up in a table, which is one read rather than a chain of them. Everything it compares is a small integer, so it asks for the same object rather than for an equal one, which is a test and not a message send. It is parenthesised as a whole: what it is written into always sends it another keyword message."

	(ranges isEmpty or: [ ranges size > 2 ]) ifTrue: [
			^ String streamContents: [ :out |
					  out
						  nextPutAll: '((';
						  nextPutAll: (self lookupFor: ranges);
						  nextPutAll: ' at: ';
						  nextPutAll: variable;
						  nextPutAll: ' + 2) == 1)' ] ].
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
	"How many turns of a repetition a written method will take before handing the match back to the engine. Each turn is a call that has not answered yet, and the engine keeps its own turns on the heap where there is more room for them."

	^ 100000
]

{ #category : 'generating' }
PCRE2MatchGenerator >> unrollLimit [
	"How many turns of a repetition may be written out in full."

	^ 8
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAlternation: children at: position indent: level then: aBlock [
	"Branches written one after another, each with everything that follows the alternation written inside it. A branch that fails falls through to the next, which is what trying them in turn amounts to here. A branch that always answers leaves the ones after it unreachable, so writing stops there."

	| stops |
	self exhausted ifTrue: [ ^ self refuse ].
	stops := false.
	children doWithIndex: [ :branch :index |
			(stops or: [ failed ]) ifFalse: [
					index > 1 ifTrue: [
							stream
								nextPut: $.;
								lf ].
					stops := index = 1
						         ifTrue: [
								         branch
									         writeInto: self
									         at: position
									         indent: level
									         then: aBlock ]
						         ifFalse: [
								         self
									         writeGuarded: [ :where :deeper |
											         branch
												         writeInto: self
												         at: where
												         indent: deeper
												         then: aBlock ]
									         at: position
									         indent: level ] ] ].
	^ stops
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAssertion: aTest at: position indent: level then: aBlock [
	"A position assertion reads nothing, so what follows it is written inside its test and goes on from the same place."

	| condition |
	self exhausted ifTrue: [ ^ self refuse ].
	aTest ifNil: [ ^ self refuse ].
	aTest first = #wordBoundary ifTrue: [
			^ self
				  writeWordBoundary: aTest
				  at: position
				  indent: level
				  then: aBlock ].
	condition := self conditionFor: aTest at: position.
	condition ifNil: [ ^ self refuse ].
	stream
		nextPutAll: (self tabs: level);
		nextPutAll: condition;
		nextPutAll: ' ifTrue: [';
		lf.
	aBlock value: position value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeAtomic: aNode at: position indent: level then: aBlock [
	"An atomic group keeps the first way it found of matching and never looks for another, which a flag says and the body reads."

	| flag held tabs outer stops |
	self exhausted ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	held := self nextName: 'h'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: ' := false. ';
		nextPutAll: held;
		nextPutAll: ' := 0.';
		lf.
	outer := guard.
	guard := flag.
	stops := aNode
		         writeInto: self
		         at: position
		         indent: level
		         then: [ :next :deeper |
				         stream
					         nextPutAll: (self tabs: deeper);
					         nextPutAll: flag;
					         nextPutAll: ' := true. ';
					         nextPutAll: held;
					         nextPutAll: ' := ';
					         nextPutAll: next.
				         false ].
	guard := outer.
	stops ifTrue: [ ^ self refuse ].
	stream
		nextPut: $.;
		lf;
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: ' ifTrue: [';
		lf.
	aBlock value: held value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeBackreference: index at: position indent: level then: aBlock [
	"A backreference reads the subject twice, where the group caught it and again here. Both are read as bytes, so either of them being 128 or over hands the whole match back to the engine."

	| tabs span same step hold start |
	self exhausted ifTrue: [ ^ self refuse ].
	(index isNil or: [ index > captures ]) ifTrue: [ ^ self refuse ].
	tabs := self tabs: level.
	start := self captureStart: index.
	span := self nextName: 'l'.
	same := self nextName: 'k'.
	step := self nextName: 'i'.
	hold := self nextName: 'p'.
	stream
		nextPutAll: tabs;
		nextPutAll: span;
		nextPutAll: ' := ';
		nextPutAll: (self captureEnd: index);
		nextPutAll: ' - ';
		nextPutAll: start;
		nextPut: $.;
		lf;
		nextPutAll: tabs;
		nextPut: $(;
		nextPutAll: start;
		nextPutAll: ' >= 0 and: [ ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: span;
		nextPutAll: ' <= size ]) ifTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: same;
		nextPutAll: ' := true. ';
		nextPutAll: step;
		nextPutAll: ' := 0.';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: '[ ';
		nextPutAll: same;
		nextPutAll: ' and: [ ';
		nextPutAll: step;
		nextPutAll: ' < ';
		nextPutAll: span;
		nextPutAll: ' ] ] whileTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: 'byte := bytes byteAt: ';
		nextPutAll: start;
		nextPutAll: ' + ';
		nextPutAll: step;
		nextPutAll: ' + 1.';
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: 'byte > 127 ifTrue: [ ^ nil ].';
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: same;
		nextPutAll: ' := byte == (bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: step;
		nextPutAll: ' + 1). ';
		nextPutAll: step;
		nextPutAll: ' := ';
		nextPutAll: step;
		nextPutAll: ' + 1 ].';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: same;
		nextPutAll: ' ifTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' + ';
		nextPutAll: span;
		nextPut: $.;
		lf.
	aBlock value: hold value: level + 3.
	stream nextPutAll: ' ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeCapture: aNode at: position indent: level then: aBlock [
	"A group remembers where it ran, and puts back what it caught the moment what follows it is done with. Putting it back around what follows, rather than around the group, is what keeps a branch of the group that did not survive from leaving its capture to the branch after it. A group inside a lookaround or an atomic group is left to the engine: what such a group catches depends on which attempt was kept, and neither of them keeps one here."

	| start finish index held |
	self exhausted ifTrue: [ ^ self refuse ].
	index := aNode index.
	(index > captures or: [ guard isNotNil ]) ifTrue: [ ^ self refuse ].
	start := self captureStart: index.
	finish := self captureEnd: index.
	held := Array with: (self nextName: 'r') with: (self nextName: 's').
	^ aNode child
		  writeInto: self
		  at: position
		  indent: level
		  then: [ :next :deeper |
				  | tabs |
				  tabs := self tabs: deeper.
				  stream
					  nextPutAll: tabs;
					  nextPutAll: held first;
					  nextPutAll: ' := ';
					  nextPutAll: start;
					  nextPutAll: '. ';
					  nextPutAll: held second;
					  nextPutAll: ' := ';
					  nextPutAll: finish;
					  nextPut: $.;
					  lf;
					  nextPutAll: tabs;
					  nextPutAll: start;
					  nextPutAll: ' := ';
					  nextPutAll: position;
					  nextPutAll: '. ';
					  nextPutAll: finish;
					  nextPutAll: ' := ';
					  nextPutAll: next;
					  nextPut: $.;
					  lf.
				  (aBlock value: next value: deeper)
					  ifTrue: [ true ]
					  ifFalse: [
							  stream
								  nextPut: $.;
								  lf;
								  nextPutAll: tabs;
								  nextPutAll: start;
								  nextPutAll: ' := ';
								  nextPutAll: held first;
								  nextPutAll: '. ';
								  nextPutAll: finish;
								  nextPutAll: ' := ';
								  nextPutAll: held second.
							  false ] ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeConditional: aNode at: position indent: level then: aBlock [
	"A conditional runs one branch or the other. A condition already settled when the pattern was read leaves only the branch it chose; one asking whether a group took part is one offset to test, and what follows the conditional is written into both branches."

	| test tabs taken missed |
	self exhausted ifTrue: [ ^ self refuse ].
	test := aNode byteCondition ifNil: [ ^ self refuse ].
	test first = #never ifTrue: [
			^ aNode elseBranch
				  writeInto: self
				  at: position
				  indent: level
				  then: aBlock ].
	test first = #always ifTrue: [
			^ aNode thenBranch
				  writeInto: self
				  at: position
				  indent: level
				  then: aBlock ].
	test second > captures ifTrue: [ ^ self refuse ].
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: (self captureEnd: test second);
		nextPutAll: ' >= 0 ifTrue: [';
		lf.
	taken := aNode thenBranch
		         writeInto: self
		         at: position
		         indent: level + 1
		         then: aBlock.
	stream
		nextPutAll: ' ] ifFalse: [';
		lf.
	missed := aNode elseBranch
		          writeInto: self
		          at: position
		          indent: level + 1
		          then: aBlock.
	stream nextPutAll: ' ]'.
	^ taken and: [ missed ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeCopy: ordinal of: aNode at: position indent: level then: aBlock [
	"One more turn of a repetition written out in full: read the item again, and where enough turns have been taken, go on without it. A greedy repetition tries the longer way first, a lazy one the shorter."

	| taken more enough stops |
	self exhausted ifTrue: [ ^ self refuse ].
	taken := ordinal - 1.
	more := ordinal <= aNode maximum.
	enough := taken >= aNode minimum.
	more ifFalse: [
			^ enough
				  ifTrue: [ aBlock value: position value: level ]
				  ifFalse: [ self refuse ] ].
	enough ifFalse: [
			^ aNode child
				  writeInto: self
				  at: position
				  indent: level
				  then: [ :next :deeper |
						  self
							  writeCopy: ordinal + 1
							  of: aNode
							  at: next
							  indent: deeper
							  then: aBlock ] ].
	aNode greedy ifFalse: [
			(aBlock value: position value: level) ifTrue: [ ^ true ].
			stream
				nextPut: $.;
				lf.
			^ self
				  writeGuarded: [ :where :deeper |
						  aNode child
							  writeInto: self
							  at: where
							  indent: deeper
							  then: [ :next :inner |
									  self
										  writeCopy: ordinal + 1
										  of: aNode
										  at: next
										  indent: inner
										  then: aBlock ] ]
				  at: position
				  indent: level ].
	stops := aNode child
		         writeInto: self
		         at: position
		         indent: level
		         then: [ :next :deeper |
				         self
					         writeCopy: ordinal + 1
					         of: aNode
					         at: next
					         indent: deeper
					         then: aBlock ].
	stops ifTrue: [ ^ true ].
	stream
		nextPut: $.;
		lf.
	^ self writeGuarded: aBlock at: position indent: level
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeGreedyRun: aNode at: position indent: level then: aBlock [
	"A greedy run of one character: counted off, handed over at its longest, then given one character back on each turn of a second loop. The count comes down before what follows is written, so that what follows is the last thing the turn does and may answer from the method."

	| ranges names run count hold tabs |
	ranges := self rangesOf: aNode child asciiTable.
	ranges ifNil: [ ^ self refuse ].
	names := self
		         writeRunUpTo: aNode maximum
		         ranges: ranges
		         from: position
		         indent: level.
	run := names first.
	count := names second.
	hold := self nextName: 'p'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: '[ '.
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
		lf;
		nextPutAll: tabs;
		tab;
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
		nextPutAll: ' - 1.';
		lf.
	aBlock value: hold value: level + 2.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeGuarded: aBlock at: position indent: level [
	"A second way of matching, which an assertion or an atomic group that has already found what it wanted does not need to try."

	guard ifNil: [ ^ aBlock value: position value: level ].
	stream
		nextPutAll: (self tabs: level);
		nextPutAll: guard;
		nextPutAll: ' ifFalse: [';
		lf.
	aBlock value: position value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLazyRun: aNode at: position indent: level then: aBlock [
	"A lazy run of one character: counted off to its minimum, handed over there, and lengthened by one character on each turn of a second loop."

	| ranges names run count hold more tabs |
	ranges := self rangesOf: aNode child asciiTable.
	ranges ifNil: [ ^ self refuse ].
	names := self
		         writeRunUpTo: aNode minimum
		         ranges: ranges
		         from: position
		         indent: level.
	run := names first.
	count := names second.
	hold := self nextName: 'p'.
	more := self nextName: 'm'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: count;
		nextPutAll: ' >= ';
		print: aNode minimum;
		nextPutAll: ' ifTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: more;
		nextPutAll: ' := true.';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: '[ ';
		nextPutAll: more.
	guard ifNotNil: [
			stream
				nextPutAll: ' and: [ ';
				nextPutAll: guard;
				nextPutAll: ' not ]' ].
	stream
		nextPutAll: ' ] whileTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPut: $.;
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: more;
		nextPutAll: ' := ';
		nextPutAll: (self
				 scanConditionOf: ranges
				 maximum: aNode maximum
				 counter: count
				 position: run);
		nextPut: $.;
		lf;
		nextPutAll: tabs;
		tab;
		tab;
		nextPutAll: more;
		nextPutAll: ' ifTrue: [ ';
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: ' + 1. ';
		nextPutAll: count;
		nextPutAll: ' := ';
		nextPutAll: count;
		nextPutAll: ' + 1 ].';
		lf.
	aBlock value: hold value: level + 3.
	stream
		nextPutAll: ' ].';
		lf;
		nextPutAll: tabs;
		tab;
		nextPut: $(;
		nextPutAll: (self fallbackConditionWithMaximum: aNode maximum counter: count position: run);
		nextPutAll: ') ifTrue: [ ^ nil ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLookahead: aNode at: position indent: level then: aBlock [
	"A lookahead reads ahead without keeping what it read. Its body is written with a flag that says it has found what it wanted, which also stops the body looking any further."

	| flag tabs outer stops |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode atomic = false ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: ' := false.';
		lf.
	outer := guard.
	guard := flag.
	stops := aNode child
		         writeInto: self
		         at: position
		         indent: level
		         then: [ :next :deeper |
				         stream
					         nextPutAll: (self tabs: deeper);
					         nextPutAll: flag;
					         nextPutAll: ' := true'.
				         false ].
	guard := outer.
	stops ifTrue: [ ^ self refuse ].
	stream
		nextPut: $.;
		lf;
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: (aNode positive
				 ifTrue: [ ' ifTrue: [' ]
				 ifFalse: [ ' ifFalse: [' ]);
		lf.
	aBlock value: position value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeLookbehind: aNode at: position indent: level then: aBlock [
	"A lookbehind reads the characters before the position. Only a branch that reads a fixed number of them is written: where such a branch begins is known without searching for it, and a branch that began inside a character would read a byte of 128 or over and hand the match back to the engine."

	| flag base tabs outer refused |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode atomic = false ifTrue: [ ^ self refuse ].
	refused := aNode branches anySatisfy: [ :branch |
			           | span |
			           span := aNode maximumLengthFor: branch.
			           span isNil or: [ span ~= (aNode minimumLengthFor: branch) ] ].
	refused ifTrue: [ ^ self refuse ].
	flag := self nextName: 'f'.
	base := self nextName: 'b'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: ' := false.';
		lf.
	outer := guard.
	guard := flag.
	aNode branches do: [ :branch |
			stream
				nextPutAll: tabs;
				nextPutAll: flag;
				nextPutAll: ' ifFalse: [';
				lf;
				nextPutAll: tabs;
				tab;
				nextPutAll: base;
				nextPutAll: ' := ';
				nextPutAll: position;
				nextPutAll: ' - ';
				print: (aNode minimumLengthFor: branch);
				nextPut: $.;
				lf;
				nextPutAll: tabs;
				tab;
				nextPutAll: base;
				nextPutAll: ' >= 0 ifTrue: [';
				lf.
			branch
				writeInto: self
				at: base
				indent: level + 2
				then: [ :next :deeper |
						stream
							nextPutAll: (self tabs: deeper);
							nextPutAll: flag;
							nextPutAll: ' := true'.
						false ].
			stream
				nextPutAll: ' ] ].';
				lf ].
	guard := outer.
	failed ifTrue: [ ^ false ].
	stream
		nextPutAll: tabs;
		nextPutAll: flag;
		nextPutAll: (aNode positive
				 ifTrue: [ ' ifTrue: [' ]
				 ifFalse: [ ' ifFalse: [' ]);
		lf.
	aBlock value: position value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writePossessiveRepeat: aNode at: position indent: level then: aBlock [
	"A possessive repetition keeps everything it read. One character repeated keeps it by having no second loop to give any back; anything else is a repetition inside an atomic group, which is what a possessive quantifier on a group means."

	self exhausted ifTrue: [ ^ self refuse ].
	aNode maximum = 0 ifTrue: [ ^ aBlock value: position value: level ].
	aNode child asciiTable ifNil: [
			^ self
				  writeAtomic: aNode
				  at: position
				  indent: level
				  then: aBlock ].
	^ self
		  writePossessiveRun: aNode
		  at: position
		  indent: level
		  then: aBlock
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writePossessiveRun: aNode at: position indent: level then: aBlock [
	"A possessive run of one character: counted off and handed over at its longest, with nothing kept to give back."

	| ranges names run count hold tabs |
	ranges := self rangesOf: aNode child asciiTable.
	ranges ifNil: [ ^ self refuse ].
	names := self
		         writeRunUpTo: aNode maximum
		         ranges: ranges
		         from: position
		         indent: level.
	run := names first.
	count := names second.
	hold := self nextName: 'p'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: count;
		nextPutAll: ' >= ';
		print: aNode minimum;
		nextPutAll: ' ifTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: hold;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPut: $.;
		lf.
	aBlock value: hold value: level + 2.
	stream nextPutAll: ' ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRecursiveRepeat: aNode at: position indent: level then: aBlock [
	"A repetition with no bound, or with more turns than are worth writing out, becomes a block that calls itself: the Smalltalk stack carries one turn per call, which is what lets a turn be given back without the body being written twice. Every local the body wants is declared in the block, so each turn has its own and a group inside the body keeps what the turn before it caught. A turn that reads nothing would never end, and what PCRE2 does with one is not what stopping there would do, so only a body that always reads a character is written this way."

	| tabs name count param mark held body inner turn rest |
	self exhausted ifTrue: [ ^ self refuse ].
	aNode child minimumLength < 1 ifTrue: [ ^ self refuse ].
	tabs := self tabs: level.
	name := self nextName: 'g'.
	count := self nextName: 'n'.
	param := self nextLabel: 'p'.
	turn := [ :where :deeper |
		        | inside maximum |
		        inside := self tabs: deeper.
		        maximum := aNode maximum.
		        maximum ifNotNil: [
				        stream
					        nextPutAll: inside;
					        nextPutAll: count;
					        nextPutAll: ' < ';
					        print: maximum;
					        nextPutAll: ' ifTrue: [';
					        lf ].
		        aNode child
			        writeInto: self
			        at: where
			        indent: (maximum ifNil: [ deeper ] ifNotNil: [ deeper + 1 ])
			        then: [ :next :within |
					        stream
						        nextPutAll: (self tabs: within);
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
		        maximum ifNotNil: [ stream nextPutAll: ' ]' ].
		        false ].
	rest := [ :where :deeper |
		        stream
			        nextPutAll: (self tabs: deeper);
			        nextPutAll: count;
			        nextPutAll: ' >= ';
			        print: aNode minimum;
			        nextPutAll: ' ifTrue: [';
			        lf.
		        aBlock value: where value: deeper + 1.
		        stream nextPutAll: ' ]'.
		        false ].
	mark := locals size.
	held := stream.
	body := (String new: 256) writeStream.
	stream := body.
	aNode greedy
		ifTrue: [
				self writeGuarded: turn at: param indent: level + 1.
				stream
					nextPut: $.;
					lf.
				self writeGuarded: rest at: param indent: level + 1 ]
		ifFalse: [
				self writeGuarded: rest at: param indent: level + 1.
				stream
					nextPut: $.;
					lf.
				self writeGuarded: turn at: param indent: level + 1 ].
	stream := held.
	inner := locals allButFirst: mark.
	locals := locals first: mark.
	failed ifTrue: [ ^ false ].
	stream
		nextPutAll: tabs;
		nextPutAll: count;
		nextPutAll: ' := 0.';
		lf;
		nextPutAll: tabs;
		nextPutAll: name;
		nextPutAll: ' := [ :';
		nextPutAll: param;
		nextPutAll: ' |';
		lf.
	inner ifNotEmpty: [
			stream
				nextPutAll: tabs;
				tab;
				nextPut: $|.
			inner do: [ :each |
					stream
						nextPut: Character space;
						nextPutAll: each ].
			stream
				nextPutAll: ' |';
				lf ].
	stream
		nextPutAll: tabs;
		tab;
		nextPutAll: count;
		nextPutAll: ' > ';
		print: self turnLimit;
		nextPutAll: ' ifTrue: [ ^ nil ].';
		lf;
		nextPutAll: body contents;
		nextPutAll: ' ].';
		lf;
		nextPutAll: tabs;
		nextPutAll: name;
		nextPutAll: ' value: ';
		nextPutAll: position.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRepeat: aNode at: position indent: level then: aBlock [
	"A repetition. One character repeated is counted off in a loop; anything else is written out once for every turn it may take."

	self exhausted ifTrue: [ ^ self refuse ].
	aNode maximum = 0 ifTrue: [ ^ aBlock value: position value: level ].
	aNode child asciiTable ifNil: [
			^ self
				  writeUnrolledRepeat: aNode
				  at: position
				  indent: level
				  then: aBlock ].
	^ aNode greedy
		  ifTrue: [
				  self
					  writeGreedyRun: aNode
					  at: position
					  indent: level
					  then: aBlock ]
		  ifFalse: [
				  self
					  writeLazyRun: aNode
					  at: position
					  indent: level
					  then: aBlock ]
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeRunUpTo: maximum ranges: ranges from: position indent: level [
	"Count off a run of one character, at most maximum of them, and answer the names holding where the run ended and how long it is. A run that stopped at a byte this cannot judge sends the whole match back to the engine."

	| run count tabs |
	run := self nextName: 'q'.
	count := self nextName: 'n'.
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: '. ';
		nextPutAll: count;
		nextPutAll: ' := 0.';
		lf;
		nextPutAll: tabs;
		nextPutAll: '[ ';
		nextPutAll: (self
				 scanConditionOf: ranges
				 maximum: maximum
				 counter: count
				 position: run);
		nextPutAll: ' ] whileTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: run;
		nextPutAll: ' := ';
		nextPutAll: run;
		nextPutAll: ' + 1. ';
		nextPutAll: count;
		nextPutAll: ' := ';
		nextPutAll: count;
		nextPutAll: ' + 1 ].';
		lf;
		nextPutAll: tabs;
		nextPut: $(;
		nextPutAll: (self fallbackConditionWithMaximum: maximum counter: count position: run);
		nextPutAll: ') ifTrue: [ ^ nil ].';
		lf.
	^ Array with: run with: count
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSequence: children at: position indent: level then: aBlock [
	"A sequence, with every item written inside the one before it, so that the Smalltalk stack carries the backtracking. The items are folded from the last to the first, which is the order in which each one learns what follows it."

	| continuation |
	continuation := aBlock.
	children reverseDo: [ :child |
			| rest |
			rest := continuation.
			continuation := [ :where :deeper |
				                child
					                writeInto: self
					                at: where
					                indent: deeper
					                then: rest ] ].
	^ continuation value: position value: level
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSingle: table at: position indent: level then: aBlock [
	"One character that is not repeated: a test, with the rest written inside it."

	| ranges tabs |
	self exhausted ifTrue: [ ^ self refuse ].
	ranges := self rangesOf: table.
	ranges ifNil: [ ^ self refuse ].
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: position;
		nextPutAll: ' < size ifTrue: [';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: 'byte := bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + 1.';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: 'byte > 127 ifTrue: [ ^ nil ].';
		lf;
		nextPutAll: tabs;
		tab;
		nextPutAll: (self testFor: ranges on: 'byte');
		nextPutAll: ' ifTrue: [';
		lf.
	aBlock value: (self offsetAfter: position) value: level + 2.
	stream nextPutAll: ' ] ]'.
	^ false
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeSuccessAt: position indent: level [
	"The match is found: say where it runs and what every group caught, and answer from the method."

	| tabs |
	tabs := self tabs: level.
	stream
		nextPutAll: tabs;
		nextPutAll: 'offsets at: 1 put: start.';
		lf;
		nextPutAll: tabs;
		nextPutAll: 'offsets at: 2 put: ';
		nextPutAll: position;
		nextPut: $.;
		lf.
	1 to: captures do: [ :index |
			stream
				nextPutAll: tabs;
				nextPutAll: 'offsets at: ';
				print: index * 2 + 1;
				nextPutAll: ' put: ';
				nextPutAll: (self captureStart: index);
				nextPutAll: '. offsets at: ';
				print: index * 2 + 2;
				nextPutAll: ' put: ';
				nextPutAll: (self captureEnd: index);
				nextPut: $.;
				lf ].
	stream
		nextPutAll: tabs;
		nextPutAll: '^ true'.
	^ true
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeUnrolledRepeat: aNode at: position indent: level then: aBlock [
	"A repetition of more than one character is written out once for every turn it may take, which is worth doing while the turns are few and what follows is not copied into many of them. More turns than that are written as a block that calls itself."

	| maximum |
	maximum := aNode maximum.
	(maximum isNil or: [ maximum > self unrollLimit or: [ maximum - aNode minimum > 2 ] ]) ifTrue: [
			^ self
				  writeRecursiveRepeat: aNode
				  at: position
				  indent: level
				  then: aBlock ].
	aNode child minimumLength < 1 ifTrue: [ ^ self refuse ].
	^ self
		  writeCopy: 1
		  of: aNode
		  at: position
		  indent: level
		  then: aBlock
]

{ #category : 'generating' }
PCRE2MatchGenerator >> writeWordBoundary: aTest at: position indent: level then: aBlock [
	"A word boundary reads the characters on both sides of the position, so the match is handed back to the engine when either of them is a byte this cannot judge. A position with no character on one side reads as a code no item accepts."

	| ranges tabs before after |
	ranges := self rangesOf: aTest third.
	ranges ifNil: [ ^ self refuse ].
	tabs := self tabs: level.
	before := self nextName: 'w'.
	after := self nextName: 'x'.
	stream
		nextPutAll: tabs;
		nextPutAll: before;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' > 0 ifTrue: [ bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' ] ifFalse: [ -1 ].';
		lf;
		nextPutAll: tabs;
		nextPutAll: after;
		nextPutAll: ' := ';
		nextPutAll: position;
		nextPutAll: ' < size ifTrue: [ bytes byteAt: ';
		nextPutAll: position;
		nextPutAll: ' + 1 ] ifFalse: [ -1 ].';
		lf;
		nextPutAll: tabs;
		nextPut: $(;
		nextPutAll: before;
		nextPutAll: ' > 127 or: [ ';
		nextPutAll: after;
		nextPutAll: ' > 127 ]) ifTrue: [ ^ nil ].';
		lf;
		nextPutAll: tabs;
		nextPut: $(;
		nextPutAll: (self testFor: ranges on: before);
		nextPutAll: ' ~~ ';
		nextPutAll: (self testFor: ranges on: after);
		nextPutAll: ') == ';
		nextPutAll: aTest second printString;
		nextPutAll: ' ifTrue: [';
		lf.
	aBlock value: position value: level + 1.
	stream nextPutAll: ' ]'.
	^ false
]
