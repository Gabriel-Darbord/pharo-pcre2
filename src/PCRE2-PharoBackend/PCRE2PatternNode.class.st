"
Abstract executable node of a pattern compiled by the Pharo backend.

Running a node means sending executeIn:state:, which pushes whatever still has to run onto the task list of the state and answers the state to continue with, or nil when the node fails. Matching is therefore an explicit loop over tasks rather than Pharo recursion, and a node that has something to restore afterwards pushes a continuation node of its own.

Nodes also answer the static facts the rest of the backend needs: length bounds for lookbehind, first-literal and start predicates for the start optimizations, whether the DFA matcher can run them, and how much runtime storage they take.
"
Class {
	#name : 'PCRE2PatternNode',
	#superclass : 'Object',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'testing' }
PCRE2PatternNode class >> isAbstract [

	^ self == PCRE2PatternNode
]

{ #category : 'matching' }
PCRE2PatternNode >> acceptIn: engine state: state [

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> acceptsEveryCharacter [
	"Whether this is the dot of a pattern compiled with dotall, which nothing in the subject refuses."

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> acceptsEveryCharacterButLineEnds [
	"Whether this is the dot of a pattern compiled without dotall, which only a line terminator refuses."

	^ false
]

{ #category : 'generating' }
PCRE2PatternNode >> asciiTable [
	"The lookup table the written matcher reads to decide whether this item accepts a byte, or nil for an item that is not one character, or one a table cannot describe. Only the entries under 128 are ever read: a written matcher hands the match back to the engine as soon as it meets a higher byte."

	^ nil
]

{ #category : 'testing' }
PCRE2PatternNode >> canAccept [

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> canAutoPossess [

	^ false
]

{ #category : 'testing' }
PCRE2PatternNode >> canBeCondition [

	^ false
]

{ #category : 'testing' }
PCRE2PatternNode >> canBeRepeated [

	^ true
]

{ #category : 'matching' }
PCRE2PatternNode >> conditionalIn: engine state: state [

	^ (self executeIn: engine state: state) isNotNil
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> dfaError [

	^ 0
]

{ #category : 'DFA matching' }
PCRE2PatternNode >> dfaKey [

	^ self
]

{ #category : 'matching' }
PCRE2PatternNode >> executeIn: engine state: state [

	self subclassResponsibility
]

{ #category : 'optimization' }
PCRE2PatternNode >> firstLiteral [

	^ nil
]

{ #category : 'optimization' }
PCRE2PatternNode >> firstLiteralPredicate [

	^ self firstLiteral ifNotNil: [ self startPredicate ]
]

{ #category : 'optimization' }
PCRE2PatternNode >> isAnchoredIn: analysis [
	"Whether a branch starting here can only match at one place, so that the engine never has to try again further along."

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> isSignificantForStart [
	"Whether the start optimizations have to look at this node, or can pass over it as PCRE2 does."

	^ true
]

{ #category : 'testing' }
PCRE2PatternNode >> isSingleCharacter [
	"Whether this node matches exactly one character and nothing else, which lets a repetition of it be counted off in one step."

	^ false
]

{ #category : 'optimization' }
PCRE2PatternNode >> isStartLineIn: analysis [
	"Whether a branch starting here can only match at the start of a line, so that the engine can jump from one line to the next."

	^ false
]

{ #category : 'accessing' }
PCRE2PatternNode >> lengthBoundsUsing: groups names: names visited: visited [

	^ {
		  self minimumLength.
		  self maximumLength }
]

{ #category : 'optimization' }
PCRE2PatternNode >> literalCharacter [

	^ nil
]

{ #category : 'accessing' }
PCRE2PatternNode >> lookbehindBranches [

	^ { self }
]

{ #category : 'accessing' }
PCRE2PatternNode >> maximumLength [

	^ nil
]

{ #category : 'accessing' }
PCRE2PatternNode >> minimumLength [

	^ 0
]

{ #category : 'parsing' }
PCRE2PatternNode >> repeatMinimum: minimum maximum: maximum greedy: greedy [

	^ PCRE2RepeatNode new
		  child: self;
		  minimum: minimum;
		  maximum: maximum;
		  greedy: greedy
]

{ #category : 'optimization' }
PCRE2PatternNode >> requiredNode [

	^ nil
]

{ #category : 'diagnostics' }
PCRE2PatternNode >> runtimeStorageSize [

	^ 0
]

{ #category : 'optimization' }
PCRE2PatternNode >> startPredicate [

	^ nil
]

{ #category : 'optimization' }
PCRE2PatternNode >> startPredicateOf: predicates [
	"One predicate standing for a group of them. A single one answers for itself rather than through a collection walked once for every start position."

	| tests |
	predicates size = 1 ifTrue: [ ^ predicates anyOne ].
	tests := predicates asArray.
	^ [ :character | tests anySatisfy: [ :test | test value: character ] ]
]

{ #category : 'testing' }
PCRE2PatternNode >> terminatesWithAccept [

	^ false
]

{ #category : 'generating' }
PCRE2PatternNode >> writeInto: aGenerator at: position indent: level then: aBlock [
	"Write this item into a generated matcher, with the block writing everything that follows it. A node a table describes is one character and is written as one test; the rest of the tree answers for itself, and what nothing answers for is left to the engine."

	^ self asciiTable ifNil: [ aGenerator refuse ] ifNotNil: [ :table |
			  aGenerator
				  writeSingle: table
				  at: position
				  indent: level
				  then: aBlock ]
]

{ #category : 'generating' }
PCRE2PatternNode >> writePossessivelyInto: aGenerator at: position indent: level then: aBlock [
	"Only a repetition can be made possessive, so anything else under a possessive quantifier is a shape this does not know."

	^ aGenerator refuse
]
