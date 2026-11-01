"
Tests for standalone `PCRE2Match` behavior.

The suite covers offset access, persistent match data, remembered subjects, and decoded match/group reads.
"
Class {
	#name : 'PCRE2MatchTest',
	#superclass : 'PCRE2FFITestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2MatchTest >> testCount [

	| match regex |
	regex := 'a' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 1.

	regex := '(a+)' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 2.

	regex := '((a+)b(c+))*' asPerlCompatibleRegex.
	match := regex findMatch: 'abc'.
	self assert: match count equals: 4
]

{ #category : 'tests' }
PCRE2MatchTest >> testDuplicateNamedGroups [

	| match regex |
	regex := '(?<part>cat)|(?<part>dog)' asPerlCompatibleRegexWithOptions: PCRE2 dupNames.
	match := regex findMatch: 'dog'.

	self assert: regex namedGroups equals: #( 'part' 'part' ).
	self assert: (match groupsNamed: 'part') equals: { nil. 'dog' }.
	self assert: (match groupNamed: 'part') equals: 'dog'
]

{ #category : 'tests' }
PCRE2MatchTest >> testFreeingAnExternalObjectLeavesItNull [
	"isNull is the question every guard asks before touching an external object, and the shutdown sweep is one of those guards. A handle that still carries the address of freed memory makes the question answer wrongly, so free nulls it. Freeing twice then does nothing, rather than handing the library a pointer it has already taken back."

	| matcher match context |
	matcher := 'a(*MARK:HELLO)b' asPerlCompatibleRegex.
	match := matcher findMatch: 'ab'.
	context := matcher context.

	self deny: matcher backend isNull.
	self deny: match backend isNull.
	self deny: context backend isNull.

	matcher free.
	match free.
	context free.

	self assert: matcher backend isNull.
	self assert: match backend isNull.
	self assert: context backend isNull.

	matcher free.
	match free.
	context free.

	self assert: matcher backend isNull
]

{ #category : 'tests' }
PCRE2MatchTest >> testGroupAccessEdgeCases [

	| match |
	match := '(?<optional>a)?b' asPerlCompatibleRegex findMatch: 'b'.

	self assert: (match groupAt: 0) equals: 'b'.
	self assert: (match groupAt: 1) isNil.
	self assert: (match groupAt: 99) isNil.
	self assert: (match groupNamed: 'optional') isNil.
	self assert: (match groupsByName at: 'optional') isNil.
	self assert: (match groupNamed: 'missing' ifAbsent: [ 'absent' ]) equals: 'absent'.

	self should: [ match groupAt: -1 ] raise: Error.
	self should: [ match groupAt: '1' ] raise: Error
]

{ #category : 'tests' }
PCRE2MatchTest >> testLastMatchIndex [

	| match |
	match := 'bc' asPerlCompatibleRegex findMatch: 'abcde'.
	self assert: match lastMatchIndex equals: 3.
	match prepareForShutdown.
	self assert: match lastMatchIndex equals: 3.

	match := 'é' asPerlCompatibleRegex findMatch: 'éé'.
	self assert: match lastMatchIndex equals: 2
]

{ #category : 'tests' }
PCRE2MatchTest >> testMarkOutlivesTheCompiledPatternItPointedInto [
	"A match keeps no reference to its matcher, so the pattern its mark pointed into can go while the match is still around. This is the guarantee a caller gets: the name is the match's own, and freeing the pattern cannot change it.

	It is a statement of the contract, not a detector of the defect it came from. Reading a freed block answers whatever now occupies it, which on a good day is still the old name, so this passed about as often as it failed before the mark was captured early. testMatchTakesItsMarkWhileTheAttemptIsBeingRecorded is what fails if the capture goes away."

	| match regex recycled |
	regex := 'a(*MARK:HELLO)b' asPerlCompatibleRegex.
	match := regex findMatch: 'ab'.
	regex free.

	recycled := (1 to: 400) collect: [ :index |
			            (String streamContents: [ :out |
					             out
						             nextPutAll: 'x(*MARK:ZZZZZZZZZZZZZZZZ';
						             print: index;
						             nextPutAll: ')y[a-z]+\d{2,4}(foo|bar|baz)' ]) asPerlCompatibleRegex ].

	self assert: match mark equals: 'HELLO'.
	self assert: recycled size equals: 400
]

{ #category : 'tests' }
PCRE2MatchTest >> testMatchDataDiagnosticsSurvivePersistence [

	| heapframesSize match matchDataSize |
	match := '(a)(b)' asPerlCompatibleRegex findMatch: 'zab'.

	matchDataSize := match matchDataSize.
	heapframesSize := match heapframesSize.

	self assert: matchDataSize isInteger.
	self assert: matchDataSize > 0.
	LibPCRE2 supportsMatchDataHeapframesSize
		ifTrue: [
				self assert: heapframesSize isInteger.
				self assert: heapframesSize >= 0 ]
		ifFalse: [ self assert: heapframesSize isNil ].

	match prepareForShutdown.

	self assert: match isPersistent.
	self assert: match matchDataSize equals: matchDataSize.
	self assert: match heapframesSize equals: heapframesSize
]

{ #category : 'tests' }
PCRE2MatchTest >> testMatchTakesItsMarkWhileTheAttemptIsBeingRecorded [
	"pcre2_get_mark answers a pointer into the compiled pattern, not into the match data, so the name has to be read while that pattern is alive. Reading the slot rather than sending #mark is the point of the test: the name must already be there before anyone asks for it."

	| match regex |
	regex := 'a(*MARK:HELLO)b' asPerlCompatibleRegex.
	match := regex findMatch: 'ab'.
	self assert: (match instVarNamed: 'mark') equals: 'HELLO'.

	"An attempt that ends on no mark has to record that too, or a later read would go back to the pointer to find out."
	regex := 'ab' asPerlCompatibleRegex.
	match := regex findMatch: 'ab'.
	self assert: (match instVarNamed: 'mark') equals: ''.
	self assert: match mark equals: nil
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroups [

	| groups match regex |
	regex := '(?<word>\p{L}+)-(?<digits>\d+)' asPerlCompatibleRegex.
	match := regex findMatch: 'café-123'.

	self assert: regex namedGroups equals: #( 'word' 'digits' ).
	self assert: match namedGroups equals: regex namedGroups.
	self assert: (match groupAt: 0) equals: 'café-123'.
	self assert: (match groupAt: 1) equals: 'café'.
	self assert: (match groupNamed: 'word') equals: 'café'.
	self assert: (match groupNamed: 'digits') equals: '123'.
	self assert: (match groupNamed: 'missing' ifAbsent: [ 'absent' ]) equals: 'absent'.

	groups := match groupsByName.
	self assert: (groups at: 'word') equals: 'café'.
	self assert: (groups at: 'digits') equals: '123'
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroupsAfterUnnamedCapture [

	| match regex |
	regex := '(a)(?<letter>b)' asPerlCompatibleRegex.
	match := regex findMatch: 'ab'.

	self assert: regex namedGroups size equals: 2.
	self assert: (regex namedGroups at: 1) equals: nil.
	self assert: (regex namedGroups at: 2) equals: 'letter'.
	self assert: (match groupNamed: 'letter') equals: 'b'
]

{ #category : 'tests' }
PCRE2MatchTest >> testNamedGroupsSurvivePersistence [

	| match |
	match := '(?<word>\w+)' asPerlCompatibleRegex findMatch: 'hello'.
	match prepareForShutdown.

	self assert: match isPersistent.
	self assert: (match groupNamed: 'word') equals: 'hello'.
	self assert: (match groupsByName at: 'word') equals: 'hello'
]

{ #category : 'tests' }
PCRE2MatchTest >> testOffsetsAt [

	| match regex |
	regex := '((a+)b(c+))*' asPerlCompatibleRegex.
	match := regex findMatch: 'aabccc'.

	self assert: (match offsetsAt: 1) equals: { 0. 6 }.
	self assert: (match offsetsAt: 2) equals: { 0. 6 }.
	self assert: (match offsetsAt: 3) equals: { 0. 2 }.
	self assert: (match offsetsAt: 4) equals: { 3. 6 }
]

{ #category : 'tests' }
PCRE2MatchTest >> testOnlyTheAttemptItselfAsksTheLibraryForAMark [
	"The MARK name is a pointer into the compiled pattern, so there is exactly one moment at which it can be read: inside the attempt that produced it. Any other sender of #getMark is a lazy read waiting to happen, and a lazy read is what walked freed memory when shutdown asked every match in the image for its mark.

	A match that never completed an attempt answers nil rather than going to look."

	| senders |
	senders := (PCRE2Match methods
		            select: [ :method | method selector ~= #getMark and: [ method messages includes: #getMark ] ]
		            thenCollect: [ :method | method selector ]) asSet.
	self assertCollection: senders hasSameElements: #( #captureMark ).

	self assert: 'a(*MARK:HELLO)b' asPerlCompatibleRegex newMatchData mark equals: nil
]

{ #category : 'tests' }
PCRE2MatchTest >> testRememberedSubjectRequiredForLateQueries [

	| regex input match |
	regex := '(a)' asPerlCompatibleRegex.
	input := 'a' asPCRE2UTF8Input.
	match := regex newMatchData.
	regex
		matchBytes: input bytes
		from: 1
		to: input size
		into: match.

	self
		should: [ match readMatch ]
		raise: Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'does not remember a subject') ].
	self
		should: [ match groupAt: 0 ]
		raise: Error
		withExceptionDo: [ :error | self assert: (error messageText includesSubstring: 'does not remember a subject') ]
]

{ #category : 'tests' }
PCRE2MatchTest >> testStandaloneMatchKeepsItsOwnResult [

	| firstMatch regex secondMatch |
	regex := '(\w+)' asPerlCompatibleRegex.

	firstMatch := regex findMatch: 'one'.
	secondMatch := regex findMatch: 'two'.

	self assert: firstMatch readMatches equals: #( 'one' 'one' ).
	self assert: secondMatch readMatches equals: #( 'two' 'two' ).
	self assert: firstMatch ovectorCount >= firstMatch count
]
