Class {
	#name : 'PCRE2Test',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2Test >> testAllOptions [

	self assert: PCRE2 allOptions equals: (Dictionary newFrom: {
				 (#compile -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #allowEmptyClass)).
						   (2 -> (PCRE2 class >> #altBSUX)).
						   (4 -> (PCRE2 class >> #autoCallout)).
						   (8 -> (PCRE2 class >> #caseless)).
						   (16 -> (PCRE2 class >> #dollarEndOnly)).
						   (32 -> (PCRE2 class >> #dotAll)).
						   (64 -> (PCRE2 class >> #dupNames)).
						   (128 -> (PCRE2 class >> #extended)).
						   (256 -> (PCRE2 class >> #firstLine)).
						   (512 -> (PCRE2 class >> #matchUnsetBackref)).
						   (1024 -> (PCRE2 class >> #multiline)).
						   (2048 -> (PCRE2 class >> #neverUCP)).
						   (4096 -> (PCRE2 class >> #neverUTF)).
						   (8192 -> (PCRE2 class >> #noAutoCapture)).
						   (16384 -> (PCRE2 class >> #noAutoPossess)).
						   (32768 -> (PCRE2 class >> #noDotstarAnchor)).
						   (65536 -> (PCRE2 class >> #noStartOptimize)).
						   (131072 -> (PCRE2 class >> #ucp)).
						   (262144 -> (PCRE2 class >> #ungreedy)).
						   (524288 -> (PCRE2 class >> #utf)).
						   (1048576 -> (PCRE2 class >> #neverBackslashC)).
						   (2097152 -> (PCRE2 class >> #altCircumflex)).
						   (4194304 -> (PCRE2 class >> #altVerbNames)).
						   (8388608 -> (PCRE2 class >> #useOffsetLimit)).
						   (16777216 -> (PCRE2 class >> #extendedMore)).
						   (33554432 -> (PCRE2 class >> #literal)).
						   (67108864 -> (PCRE2 class >> #matchInvalidUTF)).
						   (536870912 -> (PCRE2 class >> #endAnchored)).
						   (1073741824 -> (PCRE2 class >> #noUTFCheck)).
						   (2147483648 -> (PCRE2 class >> #anchored)) })).
				 (#convert -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #convertUTF)).
						   (2 -> (PCRE2 class >> #convertNoUTFCheck)).
						   (4 -> (PCRE2 class >> #convertPOSIXBasic)).
						   (8 -> (PCRE2 class >> #convertPOSIXExtended)).
						   (16 -> (PCRE2 class >> #convertGlob)).
						   (48 -> (PCRE2 class >> #convertGlobNoWildSeparator)).
						   (80 -> (PCRE2 class >> #convertGlobNoStarStar)) })).
				 (#dfa_match -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #notBOL)).
						   (2 -> (PCRE2 class >> #notEOL)).
						   (4 -> (PCRE2 class >> #notEmpty)).
						   (8 -> (PCRE2 class >> #notEmptyAtStart)).
						   (16 -> (PCRE2 class >> #partialSoft)).
						   (32 -> (PCRE2 class >> #partialHard)).
						   (64 -> (PCRE2 class >> #dfaRestart)).
						   (128 -> (PCRE2 class >> #dfaShortest)).
						   (16384 -> (PCRE2 class >> #copyMatchedSubject)).
						   (536870912 -> (PCRE2 class >> #endAnchored)).
						   (1073741824 -> (PCRE2 class >> #noUTFCheck)).
						   (2147483648 -> (PCRE2 class >> #anchored)) })).
				 (#jit_compile -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #jitComplete)).
						   (2 -> (PCRE2 class >> #jitPartialSoft)).
						   (4 -> (PCRE2 class >> #jitPartialHard)) })).
				 (#jit_match -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #notBOL)).
						   (2 -> (PCRE2 class >> #notEOL)).
						   (4 -> (PCRE2 class >> #notEmpty)).
						   (8 -> (PCRE2 class >> #notEmptyAtStart)).
						   (16 -> (PCRE2 class >> #partialSoft)).
						   (32 -> (PCRE2 class >> #partialHard)).
						   (8192 -> (PCRE2 class >> #noJIT)).
						   (16384 -> (PCRE2 class >> #copyMatchedSubject)) })).
				 (#match -> (Dictionary newFrom: {
						   (1 -> (PCRE2 class >> #notBOL)).
						   (2 -> (PCRE2 class >> #notEOL)).
						   (4 -> (PCRE2 class >> #notEmpty)).
						   (8 -> (PCRE2 class >> #notEmptyAtStart)).
						   (16 -> (PCRE2 class >> #partialSoft)).
						   (32 -> (PCRE2 class >> #partialHard)).
						   (8192 -> (PCRE2 class >> #noJIT)).
						   (16384 -> (PCRE2 class >> #copyMatchedSubject)).
						   (262144 -> (PCRE2 class >> #disableRecurseloopCheck)).
						   (536870912 -> (PCRE2 class >> #endAnchored)).
						   (1073741824 -> (PCRE2 class >> #noUTFCheck)).
						   (2147483648 -> (PCRE2 class >> #anchored)) })).
				 (#substitute -> (Dictionary newFrom: {
						   (256 -> (PCRE2 class >> #substituteGlobal)).
						   (512 -> (PCRE2 class >> #substituteExtended)).
						   (1024 -> (PCRE2 class >> #substituteUnsetEmpty)).
						   (2048 -> (PCRE2 class >> #substituteUnknownUnset)).
						   (4096 -> (PCRE2 class >> #substituteOverflowLength)).
						   (8192 -> (PCRE2 class >> #noJIT)).
						   (16384 -> (PCRE2 class >> #copyMatchedSubject)).
						   (32768 -> (PCRE2 class >> #substituteLiteral)).
						   (65536 -> (PCRE2 class >> #substituteMatched)).
						   (131072 -> (PCRE2 class >> #substituteReplacementOnly)).
						   (262144 -> (PCRE2 class >> #disableRecurseloopCheck)) })) })
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

	| options |
	options := PCRE2 autoCallout | PCRE2 dotAll | PCRE2 extended
	           | PCRE2 firstLine.
	self
		assert: (PCRE2 readOptions: options)
		equals: (Dictionary newFrom: {
					 (#compile -> (OrderedCollection
						   with: PCRE2 class >> #autoCallout
						   with: PCRE2 class >> #dotAll
						   with: PCRE2 class >> #extended
						   with: PCRE2 class >> #firstLine)).
					 (#convert
					  -> (OrderedCollection with: PCRE2 class >> #convertPOSIXBasic)).
					 (#dfa_match -> (OrderedCollection
						   with: PCRE2 class >> #notEmpty
						   with: PCRE2 class >> #partialHard
						   with: PCRE2 class >> #dfaShortest)).
					 (#jit_compile
					  -> (OrderedCollection with: PCRE2 class >> #jitPartialHard)).
					 (#jit_match -> (OrderedCollection
						   with: PCRE2 class >> #notEmpty
						   with: PCRE2 class >> #partialHard)).
					 (#match -> (OrderedCollection
						   with: PCRE2 class >> #notEmpty
						   with: PCRE2 class >> #partialHard)).
					 (#substitute
					  -> (OrderedCollection with: PCRE2 class >> #substituteGlobal)) })
]

{ #category : 'tests' }
PCRE2Test >> testReadOptionsFor [

	| regex |
	"check default options on a fresh pattern"
	regex := '' asPCRegex.

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
