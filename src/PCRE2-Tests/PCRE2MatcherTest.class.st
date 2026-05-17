"
Tests for the public `PCRE2Matcher` API.

The suite covers matching, enumeration, copying, substitution, prepared UTF-8 inputs, byte-level matching, and JIT-sensitive behavior.
"
Class {
	#name : 'PCRE2MatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2MatcherTest >> assertRegex: pattern matchPersists: subject [

	| expected match regex |
	regex := pattern asPerlCompatibleRegex.
	match := regex findMatch: subject.
	self deny: match isPersistent.
	expected := match readMatch.

	match bePersistent.

	self assert: match isPersistent.
	self assert: match readMatch equals: expected
]

{ #category : 'tests' }
PCRE2MatcherTest >> testASCIIFindAllFastPath [

	| matches |
	matches := 'a+' asPerlCompatibleRegex findAll: 'aa bb aaa'.

	self assert: matches asArray equals: #( 'aa' 'aaa' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testASCIISubjectFastPath [

	| match subject |
	subject := 'abc123'.
	match := '\w+' asPerlCompatibleRegex findMatch: subject.

	self assert: match subject identicalTo: subject.
	self assert: match decoder identicalTo: nil.
	self assert: match readMatch equals: subject
]

{ #category : 'tests' }
PCRE2MatcherTest >> testAllInfo [

	| regex infos |
	regex := '' asPerlCompatibleRegex.
	infos := regex allInfo.

	self assert: infos size equals: 27.
	self assert: (infos at: PCRE2 infoAllOptions + 1) equals: PCRE2 utf.
	self assert: (infos at: PCRE2 infoArgOptions + 1) equals: PCRE2 utf.
	self assert: (infos at: PCRE2 infoBackrefMax + 1) equals: 0.
	self assert: (infos at: PCRE2 infoCaptureCount + 1) equals: 0.
	self assert: (infos at: PCRE2 infoMatchEmpty + 1) equals: 1.
	self assert: (infos at: PCRE2 infoNameCount + 1) equals: 0.
	self assert: (infos at: PCRE2 infoSize + 1) > 0.
	self assert: (infos at: PCRE2 infoJITSize + 1) >= 0.
	self assert: (infos at: PCRE2 infoFrameSize + 1) > 0.
	self assert: (infos at: PCRE2 infoNewline + 1) isInteger
]

{ #category : 'tests' }
PCRE2MatcherTest >> testBePersistent [

	self
		assertRegex: '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
		matchPersists: 'user@example.com'.

	self
		assertRegex: '[\x{20AC}\x{00A3}\x{00A5}]'
		matchPersists: '€ $ £ ¥'.

	self
		assertRegex: '\b\w+?(?=\d)'
		matchPersists: 'not test123 this example456 another789'.

	self
		assert:
		('\d' asPerlCompatibleRegex findMatch: 'glib jocks quiz nymph to vex dwarf')
		equals: nil
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCallerManagedMatchDataCanBeReused [

	| regex input match |
	regex := '(?<word>\w+)' asPerlCompatibleRegex.
	input := 'one two' asPCRE2UTF8Input.
	match := regex newMatchData.

	regex
		matchBytes: input bytes
		from: 1
		to: input size
		into: match.
	input recordOn: match.
	self assert: match isComplete.
	self assert: match readMatch equals: 'one'.
	self assert: (match groupNamed: 'word') equals: 'one'.

	regex
		matchBytes: input bytes
		from: 5
		to: input size
		into: match.
	input recordOn: match.
	self assert: match isComplete.
	self assert: match readMatch equals: 'two'.
	self assert: (match groupNamed: 'word') equals: 'two'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCompileJIT [

	| regex originalCompiler optionsJIT |
	regex := '' asPerlCompatibleRegex.
	originalCompiler := regex compiler.
	optionsJIT := PCRE2 jitPartialHard.

	self deny: originalCompiler optionsJIT equals: optionsJIT.

	regex compileJIT: optionsJIT.

	self deny: regex compiler identicalTo: originalCompiler.
	self assert: regex compiler optionsJIT identicalTo: optionsJIT.
	self assert: regex isJIT.

	regex isJIT: false.
	regex compileJIT.
	self assert: regex isJIT
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopy [

	| regex copy |
	regex := 'a' asPerlCompatibleRegex.
	copy := regex copy.

	"structural equality"
	self deny: regex identicalTo: copy.
	self assert: regex options identicalTo: copy options.
	regex isJIT ifTrue: [ self assert: copy isJIT ].

	"match result equality"
	self assert: (regex find: 'a') equals: (copy find: 'a')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyMatchesDoAcceptsReusableUTF8Input [

	| bytesSeen input output regex |
	regex := '\p{L}+' asPerlCompatibleRegex.
	input := '1 café' asPCRE2UTF8Input.
	output := regex
		          copy: input
		          matchesDo: [ :ws :utfSubject :start :end |
			          bytesSeen := utfSubject.
			          ws nextPutAll: 'X' ].

	self assert: bytesSeen identicalTo: input bytes.
	self assert: output equals: '1 X'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyReplacingMatchesWith [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	self assert: (regex copy: '' replacingMatchesWith: '') equals: ''.
	self assert: (regex copy: 'aaa' replacingMatchesWith: '') equals: ''.
	self
		assert: (regex copy: 'aaa' replacingMatchesWith: 'b')
		equals: 'bbb'.
	self
		assert: (regex copy: 'babab' replacingMatchesWith: '_a_')
		equals: 'b_a_b_a_b'.

	"unicode"
	regex := '\p{L}+' asPerlCompatibleRegex.
	self
		assert: (regex copy: '1 café' replacingMatchesWith: 'eñe')
		equals: '1 eñe'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyReplacingMatchesWithReusableUTF8Input [

	| input regex |
	regex := '\p{L}+' asPerlCompatibleRegex.
	input := '1 café' asPCRE2UTF8Input.

	self
		assert: (regex copy: input replacingMatchesWith: 'eñe')
		equals: '1 eñe'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyTranslatingMatchesUsing [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	self
		assert: (regex copy: '' translatingMatchesUsing: [ :match | '' ])
		equals: ''.
	self
		assert: (regex copy: 'aaa' translatingMatchesUsing: [ :match | '' ])
		equals: ''.
	self
		assert:
		(regex copy: 'aaa' translatingMatchesUsing: [ :match | 'b' ])
		equals: 'bbb'.
	self
		assert: (regex
				 copy: 'babab'
				 translatingMatchesUsing: [ :match | '_' , match , '_' ])
		equals: 'b_a_b_a_b'.

	"unicode"
	regex := '\p{L}+' asPerlCompatibleRegex.
	self
		assert: (regex
				 copy: '1 café'
				 translatingMatchesUsing: [ :match | match repeat: 2 ])
		equals: '1 cafécafé'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyTranslatingMatchesUsingReusableUTF8Input [

	| input regex |
	regex := '\p{L}+' asPerlCompatibleRegex.
	input := '1 café' asPCRE2UTF8Input.

	self
		assert: (regex
				 copy: input
				 translatingMatchesUsing: [ :match | match repeat: 2 ])
		equals: '1 cafécafé'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFind [

	self assert: ('\d+' asPerlCompatibleRegex find: '123') equals: '123'.
	self assert: ('\w+' asPerlCompatibleRegex find: 'hello') equals: 'hello'.
	self
		assert:
			('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPerlCompatibleRegex find:
				 'user@example.com')
		equals: 'user@example.com'.
	self
		assert: ('\(\d{3}\) \d{3}-\d{4}' asPerlCompatibleRegex find: '(123) 456-7890')
		equals: '(123) 456-7890'.

	"no match"
	self
		assert:
		('\d' asPerlCompatibleRegex find: 'the quick brown fox jumps over the lazy dog')
		equals: nil.

	"variable-length encoding"
	self assert: ('[éèêë]' asPerlCompatibleRegex find: 'café') equals: 'é'.
	self assert: ('\p{L}+' asPerlCompatibleRegex find: 'naïve') equals: 'naïve'.
	self
		assert: ('[\x{20AC}\x{00A3}\x{00A5}]' asPerlCompatibleRegex find: '€ $ £ ¥')
		equals: '€'.
	self
		assert: ('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex find: 'Αλφα Βήτα Γάμμα')
		equals: 'Αλφα'.
	self
		assert: ('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex find: 'Привет мир')
		equals: 'Привет'.
	self
		assert: ('[\x{1F600}-\x{1F64F}]' asPerlCompatibleRegex find: '😀😃😄😁')
		equals: '😀'.
	self
		assert: ('[\x{0600}-\x{06FF}]+' asPerlCompatibleRegex find: 'مرحبا بالعالم')
		equals: 'مرحبا'.
	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPerlCompatibleRegex find: 'Hello, Привет, 你好, مرحبا')
		equals: 'Hello'.

	"lookaround and named capture groups"
	self
		assert: ('\b\w+?(?=\d)' asPerlCompatibleRegex find:
				 'not test123 this example456 another789')
		equals: 'test'.
	self
		assert: ('(?<=\d)(?:[^\d]\w+)' asPerlCompatibleRegex find:
				 'not 123test this 456example 789another')
		equals: 'test'.
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPerlCompatibleRegex find: 'user@example.com admin@domain.org')
		equals: 'user@example.com'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAll [

	self
		assert: ('\d+' asPerlCompatibleRegex findAll: '123') asArray
		equals: { '123' }.
	self
		assert: ('\w+' asPerlCompatibleRegex findAll: 'hello') asArray
		equals: { 'hello' }.
	self
		assert:
			('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPerlCompatibleRegex
				 findAll: 'user@example.com') asArray
		equals: { 'user@example.com' }.
	self
		assert:
		('\(\d{3}\) \d{3}-\d{4}' asPerlCompatibleRegex findAll: '(123) 456-7890')
			asArray
		equals: { '(123) 456-7890' }.

	"no match"
	self
		assert:
			('\d' asPerlCompatibleRegex findAll:
				 'the quick brown fox jumps over the lazy dog') asArray
		equals: {  }.

	"variable-length encoding"
	self
		assert: ('[éèêë]' asPerlCompatibleRegex findAll: 'café') asArray
		equals: { 'é' }.
	self
		assert: ('\p{L}+' asPerlCompatibleRegex findAll: 'naïve') asArray
		equals: { 'naïve' }.
	self
		assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPerlCompatibleRegex findAll: '€ $ £ ¥') asArray
		equals: { '€'. '£'. '¥' }.
	self
		assert:
		('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex findAll: 'Αλφα Βήτα Γάμμα')
			asArray
		equals: { 'Αλφα'. 'Βήτα'. 'Γάμμα' }.
	self
		assert:
		('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex findAll: 'Привет мир') asArray
		equals: { 'Привет'. 'мир' }.
	self
		assert: ('[\x{1F600}-\x{1F64F}]' asPerlCompatibleRegex findAll: '😀😃😄😁') asArray
		equals: { '😀'. '😃'. '😄'. '😁' }.
	self
		assert:
		('[\x{0600}-\x{06FF}]+' asPerlCompatibleRegex findAll: 'مرحبا بالعالم') asArray
		equals: { 'مرحبا'. 'بالعالم' }.
	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPerlCompatibleRegex findAll: 'Hello, Привет, 你好, مرحبا') asArray
		equals: { 'Hello'. 'Привет'. '你好'. 'مرحبا' }.

	"lookaround and named capture groups"
	self
		assert: ('\b\w+?(?=\d)' asPerlCompatibleRegex findAll:
				 'not test123 this example456 another789') asArray
		equals: { 'test'. 'example'. 'another' }.
	self
		assert: ('(?<=\d)(?:[^\d]\w+)' asPerlCompatibleRegex findAll:
				 'not 123test this 456example 789another') asArray
		equals: { 'test'. 'example'. 'another' }.
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPerlCompatibleRegex findAll: 'user@example.com admin@domain.org') asArray
		equals: { 'user@example.com'. 'admin@domain.org' }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAllAcceptsReusableUTF8Input [

	| input matches |
	input := 'aa bb aaa' asPCRE2UTF8Input.
	matches := 'a+' asPerlCompatibleRegex findAll: input.

	self assert: matches asArray equals: #( 'aa' 'aaa' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAllHandlesEmptyGlobalMatches [

	self
		assert: ('a*' asPerlCompatibleRegex findAll: 'aaa') asArray
		equals: #( 'aaa' '' ).
	self
		assert: ('a*?' asPerlCompatibleRegex findAll: 'aaa') asArray
		equals: #( '' 'a' '' 'a' '' 'a' '' ).
	self
		assert: ('(?=a)|a' asPerlCompatibleRegex findAll: 'a') asArray
		equals: #( '' 'a' ).
	self
		assert: ('\b' asPerlCompatibleRegex findAll: 'abc') asArray
		equals: #( '' '' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAllHandlesEmptyMatchBeforeUTF8Character [

	self
		assert: ('^' asPerlCompatibleRegex findAll: 'éa') asArray
		equals: #( '' ).
	self
		assert: ('.*?' asPerlCompatibleRegex findAll: 'éa') asArray
		equals: #( '' 'é' '' 'a' '' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAllWithGroups [

	self
		assert: ('(\w)+' asPerlCompatibleRegex findAllWithGroups: 'hello world') asArray
		equals: #( #( 'hello' 'o' ) #( 'world' 'd' ) ).
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPerlCompatibleRegex findAllWithGroups: 'user@example.com admin@domain.org')
				asArray
		equals: #( #( 'user@example.com' 'user' 'example.com' )
			   #( 'admin@domain.org' 'admin' 'domain.org' ) ).
	self
		assert:
			('([\x{0391}-\x{03C9}])+' asPerlCompatibleRegex findAllWithGroups: 'a-Αλφ-α')
				asArray
		equals: #( #( 'Αλφ' 'φ' ) #( 'α' 'α' ) )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindWithGroups [

	self
		assert: ('(\w)+' asPerlCompatibleRegex findWithGroups: 'hello')
		equals: #( 'hello' 'o' ).
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPerlCompatibleRegex findWithGroups: 'user@example.com admin@domain.org')
		equals: #( 'user@example.com' 'user' 'example.com' ).
	self
		assert:
		('([\x{0391}-\x{03C9}])+' asPerlCompatibleRegex findWithGroups: 'a-Αλφ-α')
		equals: #( 'Αλφ' 'φ' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testInfo [

	| regex infoFrameSize infoNameTable infoJITSize |
	regex := '' asPerlCompatibleRegex.

	infoFrameSize := regex info: PCRE2 infoFrameSize.
	self assert: infoFrameSize > 0.

	infoNameTable := regex info: PCRE2 infoNameTable.
	self assert: infoNameTable size equals: ExternalAddress wordSize.
	self deny: (infoNameTable allSatisfy: #isZero).

	infoJITSize := regex info: PCRE2 infoJITSize.
	self assert: infoJITSize >= 0
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMark [

	| regex |
	regex := '' asPerlCompatibleRegex.
	self assert: (regex findMatch: '') mark equals: nil.

	regex := '(*MARK:bye)((*MARK:café)A|D)C' asPerlCompatibleRegex.
	self assert: (regex findMatch: 'AC') mark equals: 'café'.
	self assert: (regex findMatch: 'DC') mark equals: 'bye'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchAllOffsetsDo [

	| input offsets regex |
	regex := 'ab' asPerlCompatibleRegex.
	input := 'ab ab' asPCRE2UTF8Input.
	offsets := OrderedCollection new.

	regex
		matchAll: input bytes
		from: 1
		to: input size
		offsetsDo: [ :each | offsets add: each ].

	self assert: offsets asArray equals: {
			#( 0 2 ).
			#( 3 5 ) }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchContextLimitsAndCopy [

	| regex context copy |
	regex := 'a' asPerlCompatibleRegex.
	context := regex context.

	context
		depthLimit: 10;
		heapLimit: 100;
		matchLimit: 1000;
		offsetLimit: 3.

	self assert: context depthLimit equals: 10.
	self assert: context heapLimit equals: 100.
	self assert: context matchLimit equals: 1000.
	self assert: context offsetLimit equals: 3.

	copy := context copy.
	[
	self deny: copy identicalTo: context.
	self assert: copy depthLimit equals: context depthLimit.
	self assert: copy heapLimit equals: context heapLimit.
	self assert: copy matchLimit equals: context matchLimit.
	self assert: copy offsetLimit equals: context offsetLimit ] ensure: [
		copy free ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchLimit [

	| regex |
	regex := '(a+)+' asPerlCompatibleRegex.
	regex context matchLimit: 1.

	self
		should: [ regex matches: 'aa' ]
		raise: PCRE2MatchError
		withExceptionDo: [ :e |
		self assert: e messageText equals: 'match limit exceeded' ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatcherNoLongerStoresMatchData [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	self
		should: [ regex matchData ]
		raise: Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'no longer keeps match data') ].
	self
		should: [ regex matchData: regex newMatchData ]
		raise: Error
		withExceptionDo: [ :error |
			self assert: (error messageText includesSubstring:
					 'no longer accepts stored match data') ].
	self should: [ regex mark ] raise: Error withExceptionDo: [ :error |
		self assert:
			(error messageText includesSubstring:
				 'no longer keeps the last match') ].
	self
		should: [ regex startIndex ]
		raise: Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring:
					 'no longer keeps the last match') ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatcherOptionsCanBeSetAddedAndRemoved [

	| regex |
	regex := 'a' asPerlCompatibleRegex.

	regex options: 0.
	self assert: regex options equals: 0.
	regex addOptions: PCRE2 caseless.
	self assert: regex options equals: PCRE2 caseless.
	regex removeOptions: PCRE2 caseless.
	self assert: regex options equals: 0
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatches [

	self assert: ('\d+' asPerlCompatibleRegex matches: '123').
	self assert: ('\w+' asPerlCompatibleRegex matches: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPerlCompatibleRegex
			 matches: 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPerlCompatibleRegex matches: '(123) 456-7890').

	"no match"
	self deny:
		('\d' asPerlCompatibleRegex matches:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self deny: ('[éèêë]' asPerlCompatibleRegex matches: 'café').
	self assert: ('\p{L}+' asPerlCompatibleRegex matches: 'naïve').
	self deny:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPerlCompatibleRegex matches: '€ $ £ ¥').
	self deny:
		('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex matches: 'Αλφα Βήτα Γάμμα').
	self deny: ('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex matches: 'Привет мир').
	self deny: ('[\x{1F600}-\x{1F64F}]' asPerlCompatibleRegex matches: '😀😃😄😁').
	self deny:
		('[\x{0600}-\x{06FF}]+' asPerlCompatibleRegex matches: 'مرحبا بالعالم').
	self deny:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPerlCompatibleRegex matches: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self deny: ('\b\w+?(?=\d)' asPerlCompatibleRegex matches:
			 'not test123 this example456 another789').
	self deny: ('(?<=\d)(?:[^\d]\w+)' asPerlCompatibleRegex matches:
			 'not 123test this 456example 789another').
	self deny:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPerlCompatibleRegex matches: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchesInCollect [

	self
		assert: ('\d' asPerlCompatibleRegex
				 matchesIn: '123'
				 collect: [ :match | match asInteger + 1 ]) asArray
		equals: #( 2 3 4 ).

	self
		assert: ('\w' asPerlCompatibleRegex
				 matchesIn: 'hello'
				 collect: [ :match | match first asciiValue ]) asArray
		equals: #( 104 101 108 108 111 ).

	"no match"
	self assert: ('\d' asPerlCompatibleRegex
			 matchesIn: 'the quick brown fox jumps over the lazy dog'
			 collect: [ :match | match ]) isEmpty.

	"variable-length encoding"
	self
		assert: ('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex
				 matchesIn: 'Αλφα Βήτα Γάμμα'
				 collect: [ :match | match size ]) asArray
		equals: #( 4 4 5 ).

	self
		assert: ('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex
				 matchesIn: 'Привет мир'
				 collect: [ :match | match size ]) asArray
		equals: #( 6 3 ).

	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPerlCompatibleRegex
				 matchesIn: 'Hello, Привет, 你好, مرحبا'
				 collect: [ :match | match size ]) asArray
		equals: #( 5 6 2 5 )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchesPrefix [

	self assert: ('\d+' asPerlCompatibleRegex matchesPrefix: '123').
	self assert: ('\w+' asPerlCompatibleRegex matchesPrefix: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPerlCompatibleRegex
			 matchesPrefix: 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPerlCompatibleRegex matchesPrefix: '(123) 456-7890').

	"no match"
	self deny: ('\d' asPerlCompatibleRegex matchesPrefix:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self deny: ('[éèêë]' asPerlCompatibleRegex matchesPrefix: 'café').
	self assert: ('\p{L}+' asPerlCompatibleRegex matchesPrefix: 'naïve').
	self assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPerlCompatibleRegex matchesPrefix: '€ $ £ ¥').
	self assert:
		('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex matchesPrefix: 'Αλφα Βήτα Γάμμα').
	self assert:
		('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex matchesPrefix: 'Привет мир').
	self assert:
		('[\x{1F600}-\x{1F64F}]' asPerlCompatibleRegex matchesPrefix: '😀😃😄😁').
	self assert:
		('[\x{0600}-\x{06FF}]+' asPerlCompatibleRegex matchesPrefix: 'مرحبا بالعالم').
	self assert:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPerlCompatibleRegex matchesPrefix: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self deny: ('\b\w+?(?=\d)' asPerlCompatibleRegex matchesPrefix:
			 'not test123 this example456 another789').
	self deny: ('(?<=\d)(?:[^\d]\w+)' asPerlCompatibleRegex matchesPrefix:
			 'not 123test this 456example 789another').
	self assert:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPerlCompatibleRegex matchesPrefix: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchingRangesInASCIIString [

	| ranges |
	ranges := 'a+' asPerlCompatibleRegex matchingRangesIn: 'baaa ca'.

	self assert: ranges asArray equals: {
			(2 to: 4).
			(7 to: 7) }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchingRangesInReusableUTF8Input [

	| input ranges |
	input := '1 café' asPCRE2UTF8Input.
	ranges := '\p{L}+' asPerlCompatibleRegex matchingRangesIn: input.

	self assert: ranges asArray equals: { (3 to: 6) }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchingRangesInUnicodeString [

	| ranges |
	ranges := '\p{L}+' asPerlCompatibleRegex matchingRangesIn: '1 café 23 λx'.

	self assert: ranges asArray equals: {
			(3 to: 6).
			(11 to: 12) }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testNonASCIIByteStringSubjectIsEncoded [

	| match subject |
	subject := 'café'.
	match := 'é' asPerlCompatibleRegex findMatch: subject.

	self deny: match subject identicalTo: subject.
	self
		assert: match subject
		equals: (ZnUTF8Encoder default encodeString: subject).
	self assert: match decoder class equals: ZnUTF8Encoder.
	self assert: match readMatch equals: 'é'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testRawMatchAllHandlesEmptyGlobalMatches [

	| matches |
	matches := OrderedCollection new.
	'a*?' asPerlCompatibleRegex
		matchAll: 'aaa'
		from: 1
		to: 3
		do: [ :match | matches add: match readMatch ].

	self assert: matches asArray equals: #( '' 'a' '' 'a' '' 'a' '' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testRecompile [

	self assert: ('a' asPerlCompatibleRegex finalize recompile matches: 'a')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testRegexAPIMatchEnumerationCompatibility [

	| collected regex seen |
	regex := '\w+' asPerlCompatibleRegex.

	self
		assert: (regex matchesIn: 'one two') asArray
		equals: #( 'one' 'two' ).
	seen := OrderedCollection new.
	regex matchesIn: 'one two' do: [ :match | seen add: match ].
	self assert: seen asArray equals: #( 'one' 'two' ).
	collected := regex
		             matchesIn: 'one two'
		             collect: [ :match | match asUppercase ].
	self assert: collected asArray equals: #( 'ONE' 'TWO' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testReusableASCIIInputKeepsOriginalStorage [

	| input match subject |
	subject := 'abc123'.
	input := subject asPCRE2UTF8Input.
	match := '\w+' asPerlCompatibleRegex findMatch: input.

	self assert: input bytes identicalTo: subject.
	self assert: match subject identicalTo: input bytes.
	self assert: match decoder identicalTo: nil.
	self assert: match readMatch equals: subject
]

{ #category : 'tests' }
PCRE2MatcherTest >> testReusableMatchDataRejectsPersistentMatchData [

	| regex input match |
	regex := 'a' asPerlCompatibleRegex.
	input := 'a' asPCRE2UTF8Input.
	match := regex findMatch: input.
	match bePersistent.

	self
		should: [
			regex
				matchBytes: input bytes
				from: 1
				to: input size
				into: match ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'external PCRE2 match data') ].
	self
		should: [
			regex
				dfaMatchBytes: input bytes
				from: 1
				to: input size
				workspaceSize: 20
				ovectorSize: 1
				into: match ]
		raise: PCRE2Error
		withExceptionDo: [ :error |
			self assert:
				(error messageText includesSubstring: 'external PCRE2 match data') ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testReusableUTF8InputAvoidsReencoding [

	| first input second |
	input := 'café' asPCRE2UTF8Input.
	first := 'é' asPerlCompatibleRegex findMatch: input.
	second := '\p{L}+' asPerlCompatibleRegex findMatch: input.

	self assert: first subject identicalTo: input bytes.
	self assert: second subject identicalTo: input bytes.
	self assert: first decoder identicalTo: input decoder.
	self assert: second decoder identicalTo: input decoder.
	self assert: first readMatch equals: 'é'.
	self assert: second readMatch equals: 'café'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSearch [

	self assert: ('\d+' asPerlCompatibleRegex search: '123').
	self assert: ('\w+' asPerlCompatibleRegex search: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPerlCompatibleRegex search:
			 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPerlCompatibleRegex search: '(123) 456-7890').

	"no match"
	self deny:
		('\d' asPerlCompatibleRegex search:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self assert: ('[éèêë]' asPerlCompatibleRegex search: 'café').
	self assert: ('\p{L}+' asPerlCompatibleRegex search: 'naïve').
	self assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPerlCompatibleRegex search: '€ $ £ ¥').
	self assert:
		('[\x{0391}-\x{03C9}]+' asPerlCompatibleRegex search: 'Αλφα Βήτα Γάμμα').
	self assert: ('[\x{0400}-\x{04FF}]+' asPerlCompatibleRegex search: 'Привет мир').
	self assert: ('[\x{1F600}-\x{1F64F}]' asPerlCompatibleRegex search: '😀😃😄😁').
	self assert:
		('[\x{0600}-\x{06FF}]+' asPerlCompatibleRegex search: 'مرحبا بالعالم').
	self assert:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPerlCompatibleRegex search: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self assert: ('\b\w+?(?=\d)' asPerlCompatibleRegex search:
			 'not test123 this example456 another789').
	self assert: ('(?<=\d)(?:[^\d]\w+)' asPerlCompatibleRegex search:
			 'not 123test this 456example 789another').
	self assert:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPerlCompatibleRegex search: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSplitIndicesDoAcceptsReusableUTF8Input [

	| indices input |
	indices := OrderedCollection new.
	input := 'café déjà' asPCRE2UTF8Input.
	'é' asPerlCompatibleRegex split: input indicesDo: [ :start :end |
		indices add: {
				start.
				end } ].

	self assert: indices asArray equals: {
			{ 1. 3 }.
			{ 5. 6 }.
			{ 8. 9 } }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSplitRejectsEmptyRegex [

	self
		should: [ '' asPerlCompatibleRegex split: 'abc' ]
		raise: AssertionFailure
		withExceptionDo: [ :error |
			self
				assert: error messageText
				equals: 'Regex cannot match null string' ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSplitStringOnPerlCompatibleRegex [

	self
		assert: ('foobar' splitOn: '[aeiou]+' asPerlCompatibleRegex)
		equals: #( 'f' 'b' 'r' ) asOrderedCollection
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSplitStringOnPerlCompatibleRegexBoundaryCases [

	self
		assert: (',a,b' splitOn: ',' asPerlCompatibleRegex)
		equals: #( '' 'a' 'b' ) asOrderedCollection.
	self
		assert: ('a,b,' splitOn: ',' asPerlCompatibleRegex)
		equals: #( 'a' 'b' '' ) asOrderedCollection.
	self
		assert: ('a,,b' splitOn: ',' asPerlCompatibleRegex)
		equals: #( 'a' '' 'b' ) asOrderedCollection
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSplitStringOnPerlCompatibleRegexUnicode [

	self
		assert: ('café déjà' splitOn: 'é' asPerlCompatibleRegex)
		equals: #( 'caf' ' d' 'jà' ) asOrderedCollection
]

{ #category : 'tests' }
PCRE2MatcherTest >> testStartIndex [

	| regex |
	regex := 'bc' asPerlCompatibleRegex.
	self assert: (regex findMatch: 'abc') startIndex equals: 2
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSubstituteAcceptsReusableUTF8Input [

	| input regex |
	regex := 'é' asPerlCompatibleRegex.
	regex addOptions: PCRE2 substituteGlobal.
	input := 'café café' asPCRE2UTF8Input.

	self assert: (regex substitute: input with: 'e') equals: 'cafe cafe'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSubstituteCanAnswerEmptyString [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	regex addOptions: PCRE2 substituteGlobal.

	self assert: (regex substitute: 'aaa' with: '') equals: ''.
	self
		assert: (regex substitute: 'aaa' asPCRE2UTF8Input with: '')
		equals: ''
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSubstituteDecodesUTF8Output [

	| regex |
	regex := 'a' asPerlCompatibleRegex.
	regex addOptions: PCRE2 substituteGlobal.

	self assert: (regex substitute: 'aaa' with: 'é') equals: 'ééé'.
	self
		assert:
		(regex substitute: 'aaa' asPCRE2UTF8Input with: 'é' asPCRE2UTF8Input)
		equals: 'ééé'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testWithOffsetLimit [

	| regex |
	regex := 'B' asPerlCompatibleRegexWithOptions: PCRE2 useOffsetLimit.
	regex addOptions: PCRE2 substituteGlobal.
	regex context offsetLimit: 6.

	self
		assert: (regex substitute: 'ABC ABC ABC ABC' with: '!')
		equals: 'A!C A!C ABC ABC'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testZeroTerminated [

	| encoder match regex subject utfSubject |
	regex := '.*' asPerlCompatibleRegex.
	subject := 'abc' , Character null asString , 'def'.
	encoder := ZnUTF8Encoder default.
	utfSubject := encoder encodeString: subject.

	"jit_match() does not support null-terminated string subjects; disable the fast path for support."
	regex isJIT: false.

	match := regex
		         matchBytes: utfSubject
		         from: 1
		         to: PCRE2 zeroTerminated.
	self assert: match count equals: 1.
	self assert: (encoder decodeBytes: match readMatch) equals: 'abc'
]
