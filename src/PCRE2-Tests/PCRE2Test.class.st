"
Tests for PCRE2 constants and option metadata.

The suite protects the option tables used to explain and validate compile, match, DFA, JIT, substitute, and convert flags.
"
Class {
	#name : 'PCRE2Test',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'private' }
PCRE2Test >> optionSelectorsFrom: optionsByFunction [

	^ optionsByFunction collect: [ :optionsByValue |
		  optionsByValue collect: [ :method | method selector ] ]
]

{ #category : 'tests' }
PCRE2Test >> testAbstractClassDeclarations [

	| abstractClasses concreteClasses |
	abstractClasses := {
		                   PCRE2Object.
		                   PCRE2CompileContext.
		                   PCRE2Compiler.
		                   PCRE2JITStack.
		                   PCRE2Match.
		                   PCRE2MatchContext.
		                   PCRE2Matcher }.
	concreteClasses := {
		                   PCRE2UTF8CompileContext.
		                   PCRE2UTF16CompileContext.
		                   PCRE2UTF32CompileContext.
		                   PCRE2UTF8Compiler.
		                   PCRE2UTF16Compiler.
		                   PCRE2UTF32Compiler.
		                   PCRE2UTF8JITStack.
		                   PCRE2UTF16JITStack.
		                   PCRE2UTF32JITStack.
		                   PCRE2UTF8Match.
		                   PCRE2UTF16Match.
		                   PCRE2UTF32Match.
		                   PCRE2UTF8MatchContext.
		                   PCRE2UTF16MatchContext.
		                   PCRE2UTF32MatchContext.
		                   PCRE2UTF8Matcher.
		                   PCRE2UTF16Matcher.
		                   PCRE2UTF32Matcher }.

	abstractClasses do: [ :each | self assert: each isAbstract ].
	concreteClasses do: [ :each | self deny: each isAbstract ]
]

{ #category : 'tests' }
PCRE2Test >> testAllOptions [

	| expected |
	expected := Dictionary newFrom: {
			            (#compile -> (Dictionary newFrom: {
					              (1 -> #allowEmptyClass).
					              (2 -> #altBSUX).
					              (4 -> #autoCallout).
					              (8 -> #caseless).
					              (16 -> #dollarEndOnly).
					              (32 -> #dotAll).
					              (64 -> #dupNames).
					              (128 -> #extended).
					              (256 -> #firstLine).
					              (512 -> #matchUnsetBackref).
					              (1024 -> #multiline).
					              (2048 -> #neverUCP).
					              (4096 -> #neverUTF).
					              (8192 -> #noAutoCapture).
					              (16384 -> #noAutoPossess).
					              (32768 -> #noDotstarAnchor).
					              (65536 -> #noStartOptimize).
					              (131072 -> #ucp).
					              (262144 -> #ungreedy).
					              (524288 -> #utf).
					              (1048576 -> #neverBackslashC).
					              (2097152 -> #altCircumflex).
					              (4194304 -> #altVerbNames).
					              (8388608 -> #useOffsetLimit).
					              (16777216 -> #extendedMore).
					              (33554432 -> #literal).
					              (67108864 -> #matchInvalidUTF).
					              (536870912 -> #endAnchored).
					              (1073741824 -> #noUTFCheck).
					              (2147483648 -> #anchored) })).
			            (#convert -> (Dictionary newFrom: {
					              (1 -> #convertUTF).
					              (2 -> #convertNoUTFCheck).
					              (4 -> #convertPOSIXBasic).
					              (8 -> #convertPOSIXExtended).
					              (16 -> #convertGlob).
					              (48 -> #convertGlobNoWildSeparator).
					              (80 -> #convertGlobNoStarStar) })).
			            (#dfa_match -> (Dictionary newFrom: {
					              (1 -> #notBOL).
					              (2 -> #notEOL).
					              (4 -> #notEmpty).
					              (8 -> #notEmptyAtStart).
					              (16 -> #partialSoft).
					              (32 -> #partialHard).
					              (64 -> #dfaRestart).
					              (128 -> #dfaShortest).
					              (16384 -> #copyMatchedSubject).
					              (536870912 -> #endAnchored).
					              (1073741824 -> #noUTFCheck).
					              (2147483648 -> #anchored) })).
			            (#jit_compile -> (Dictionary newFrom: {
					              (1 -> #jitComplete).
					              (2 -> #jitPartialSoft).
					              (4 -> #jitPartialHard) })).
			            (#jit_match -> (Dictionary newFrom: {
					              (1 -> #notBOL).
					              (2 -> #notEOL).
					              (4 -> #notEmpty).
					              (8 -> #notEmptyAtStart).
					              (16 -> #partialSoft).
					              (32 -> #partialHard).
					              (8192 -> #noJIT).
					              (16384 -> #copyMatchedSubject) })).
			            (#match -> (Dictionary newFrom: {
					              (1 -> #notBOL).
					              (2 -> #notEOL).
					              (4 -> #notEmpty).
					              (8 -> #notEmptyAtStart).
					              (16 -> #partialSoft).
					              (32 -> #partialHard).
					              (8192 -> #noJIT).
					              (16384 -> #copyMatchedSubject).
					              (262144 -> #disableRecurseloopCheck).
					              (536870912 -> #endAnchored).
					              (1073741824 -> #noUTFCheck).
					              (2147483648 -> #anchored) })).
			            (#substitute -> (Dictionary newFrom: {
					              (256 -> #substituteGlobal).
					              (512 -> #substituteExtended).
					              (1024 -> #substituteUnsetEmpty).
					              (2048 -> #substituteUnknownUnset).
					              (4096 -> #substituteOverflowLength).
					              (8192 -> #noJIT).
					              (16384 -> #copyMatchedSubject).
					              (32768 -> #substituteLiteral).
					              (65536 -> #substituteMatched).
					              (131072 -> #substituteReplacementOnly).
					              (262144 -> #disableRecurseloopCheck) })) }.

	self
		assert: (self optionSelectorsFrom: PCRE2 allOptions)
		equals: expected
]

{ #category : 'tests' }
PCRE2Test >> testOptionsFor [

	self assert: (PCRE2 optionsFor: #compile) size equals: 30.
	self assert: (PCRE2 optionsFor: #jit_compile) size equals: 3.
	self assert: (PCRE2 optionsFor: #match) size equals: 12.
	self assert: (PCRE2 optionsFor: #jit_match) size equals: 8.
	self assert: (PCRE2 optionsFor: #dfa_match) size equals: 12.
	self assert: (PCRE2 optionsFor: #substitute) size equals: 11.
	self assert: (PCRE2 optionsFor: #convert) size equals: 7
]

{ #category : 'tests' }
PCRE2Test >> testReadOptions [
	"Options are flags with different meanings depending on the function to which they are applied."

	| options expected actual |
	options := PCRE2 autoCallout | PCRE2 dotAll | PCRE2 extended
	           | PCRE2 firstLine.

	actual := PCRE2 readOptions: options.

	(expected := Dictionary new)
		at: #compile put: (OrderedCollection
				 with: PCRE2 class >> #autoCallout
				 with: PCRE2 class >> #dotAll
				 with: PCRE2 class >> #extended
				 with: PCRE2 class >> #firstLine);
		at: #convert
		put: (OrderedCollection with: PCRE2 class >> #convertPOSIXBasic);
		at: #dfa_match put: (OrderedCollection
				 with: PCRE2 class >> #notEmpty
				 with: PCRE2 class >> #partialHard
				 with: PCRE2 class >> #dfaShortest);
		at: #jit_compile
		put: (OrderedCollection with: PCRE2 class >> #jitPartialHard);
		at: #jit_match put: (OrderedCollection
				 with: PCRE2 class >> #notEmpty
				 with: PCRE2 class >> #partialHard);
		at: #match put: (OrderedCollection
				 with: PCRE2 class >> #notEmpty
				 with: PCRE2 class >> #partialHard);
		at: #substitute
		put: (OrderedCollection with: PCRE2 class >> #substituteGlobal).

	"assert:equals: should work, but it does not pass in the CI on Ubuntu"
	expected keysAndValuesDo: [ :key :value |
		self assertCollection: (actual at: key) hasSameElements: value ]
]

{ #category : 'tests' }
PCRE2Test >> testReadOptionsFor [

	| regex |
	"check default options on a fresh pattern"
	regex := '' asPerlCompatibleRegex.

	self assert: (PCRE2 readOptions: regex options for: #match) isEmpty.

	self
		assert: (PCRE2 readOptions: regex compiler options for: #compile)
		equals: (OrderedCollection with: PCRE2 class >> #utf).

	self
		assert:
		(PCRE2 readOptions: regex compiler optionsJIT for: #jit_compile)
		equals: (OrderedCollection with: PCRE2 class >> #jitComplete).

	"check that some match() options are recognized"
	self
		assert: (PCRE2
				 readOptions:
				 PCRE2 notEmpty | PCRE2 noJIT | PCRE2 noUTFCheck | PCRE2 anchored
				 for: #match)
		equals: (OrderedCollection
				 with: PCRE2 class >> #notEmpty
				 with: PCRE2 class >> #noJIT
				 with: PCRE2 class >> #noUTFCheck
				 with: PCRE2 class >> #anchored)
]
