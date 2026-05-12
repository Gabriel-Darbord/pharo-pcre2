Class {
	#name : 'PCRE2MatcherTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2MatcherTest >> assertRegex: pattern matchPersists: subject [

	| expected match regex |
	regex := pattern asPCRegex.
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
	matches := 'a+' asPCRegex findAll: 'aa bb aaa'.

	self assert: matches asArray equals: #( 'aa' 'aaa' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testASCIISubjectFastPath [

	| match subject |
	subject := 'abc123'.
	match := '\w+' asPCRegex findMatch: subject.

	self assert: match subject identicalTo: subject.
	self assert: match decoder identicalTo: nil.
	self assert: match readMatch equals: subject
]

{ #category : 'tests' }
PCRE2MatcherTest >> testAllInfo [

	| regex infos |
	regex := '' asPCRegex.
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
		('\d' asPCRegex findMatch: 'glib jocks quiz nymph to vex dwarf')
		equals: nil
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCompileJIT [

	| regex originalCompiler optionsJIT |
	regex := '' asPCRegex.
	originalCompiler := regex compiler.
	optionsJIT := PCRE2 jitPartialHard.

	self deny: originalCompiler optionsJIT equals: optionsJIT.

	regex compileJIT: optionsJIT.

	self deny: regex compiler identicalTo: originalCompiler.
	self assert: regex compiler optionsJIT identicalTo: optionsJIT
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopy [

	| regex copy |
	regex := 'a' asPCRegex.
	copy := regex copy.

	"structural equality"
	self deny: regex identicalTo: copy.
	self assert: regex options identicalTo: copy options.
	regex isJIT ifTrue: [ self assert: copy isJIT ].

	"match result equality"
	self assert: (regex find: 'a') equals: (copy find: 'a')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyReplacingMatchesWith [

	| regex |
	regex := 'a' asPCRegex.
	self assert: (regex copy: '' replacingMatchesWith: '') equals: ''.
	self assert: (regex copy: 'aaa' replacingMatchesWith: '') equals: ''.
	self
		assert: (regex copy: 'aaa' replacingMatchesWith: 'b')
		equals: 'bbb'.
	self
		assert: (regex copy: 'babab' replacingMatchesWith: '_a_')
		equals: 'b_a_b_a_b'.

	"unicode"
	regex := '\p{L}+' asPCRegex.
	self
		assert: (regex copy: '1 café' replacingMatchesWith: 'eñe')
		equals: '1 eñe'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testCopyTranslatingMatchesUsing [

	| regex |
	regex := 'a' asPCRegex.
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
	regex := '\p{L}+' asPCRegex.
	self
		assert: (regex
				 copy: '1 café'
				 translatingMatchesUsing: [ :match | match repeat: 2 ])
		equals: '1 cafécafé'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFind [

	self assert: ('\d+' asPCRegex find: '123') equals: '123'.
	self assert: ('\w+' asPCRegex find: 'hello') equals: 'hello'.
	self
		assert:
			('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPCRegex find:
				 'user@example.com')
		equals: 'user@example.com'.
	self
		assert: ('\(\d{3}\) \d{3}-\d{4}' asPCRegex find: '(123) 456-7890')
		equals: '(123) 456-7890'.

	"no match"
	self
		assert:
		('\d' asPCRegex find: 'the quick brown fox jumps over the lazy dog')
		equals: nil.

	"variable-length encoding"
	self assert: ('[éèêë]' asPCRegex find: 'café') equals: 'é'.
	self assert: ('\p{L}+' asPCRegex find: 'naïve') equals: 'naïve'.
	self
		assert: ('[\x{20AC}\x{00A3}\x{00A5}]' asPCRegex find: '€ $ £ ¥')
		equals: '€'.
	self
		assert: ('[\x{0391}-\x{03C9}]+' asPCRegex find: 'Αλφα Βήτα Γάμμα')
		equals: 'Αλφα'.
	self
		assert: ('[\x{0400}-\x{04FF}]+' asPCRegex find: 'Привет мир')
		equals: 'Привет'.
	self
		assert: ('[\x{1F600}-\x{1F64F}]' asPCRegex find: '😀😃😄😁')
		equals: '😀'.
	self
		assert: ('[\x{0600}-\x{06FF}]+' asPCRegex find: 'مرحبا بالعالم')
		equals: 'مرحبا'.
	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPCRegex find: 'Hello, Привет, 你好, مرحبا')
		equals: 'Hello'.

	"lookaround and named capture groups"
	self
		assert: ('\b\w+?(?=\d)' asPCRegex find:
				 'not test123 this example456 another789')
		equals: 'test'.
	self
		assert: ('(?<=\d)(?:[^\d]\w+)' asPCRegex find:
				 'not 123test this 456example 789another')
		equals: 'test'.
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPCRegex find: 'user@example.com admin@domain.org')
		equals: 'user@example.com'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAll [

	self
		assert: ('\d+' asPCRegex findAll: '123') asArray
		equals: { '123' }.
	self
		assert: ('\w+' asPCRegex findAll: 'hello') asArray
		equals: { 'hello' }.
	self
		assert:
			('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPCRegex
				 findAll: 'user@example.com') asArray
		equals: { 'user@example.com' }.
	self
		assert:
		('\(\d{3}\) \d{3}-\d{4}' asPCRegex findAll: '(123) 456-7890')
			asArray
		equals: { '(123) 456-7890' }.

	"no match"
	self
		assert:
			('\d' asPCRegex findAll:
				 'the quick brown fox jumps over the lazy dog') asArray
		equals: {  }.

	"variable-length encoding"
	self
		assert: ('[éèêë]' asPCRegex findAll: 'café') asArray
		equals: { 'é' }.
	self
		assert: ('\p{L}+' asPCRegex findAll: 'naïve') asArray
		equals: { 'naïve' }.
	self
		assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPCRegex findAll: '€ $ £ ¥') asArray
		equals: { '€'. '£'. '¥' }.
	self
		assert:
		('[\x{0391}-\x{03C9}]+' asPCRegex findAll: 'Αλφα Βήτα Γάμμα')
			asArray
		equals: { 'Αλφα'. 'Βήτα'. 'Γάμμα' }.
	self
		assert:
		('[\x{0400}-\x{04FF}]+' asPCRegex findAll: 'Привет мир') asArray
		equals: { 'Привет'. 'мир' }.
	self
		assert: ('[\x{1F600}-\x{1F64F}]' asPCRegex findAll: '😀😃😄😁') asArray
		equals: { '😀'. '😃'. '😄'. '😁' }.
	self
		assert:
		('[\x{0600}-\x{06FF}]+' asPCRegex findAll: 'مرحبا بالعالم') asArray
		equals: { 'مرحبا'. 'بالعالم' }.
	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPCRegex findAll: 'Hello, Привет, 你好, مرحبا') asArray
		equals: { 'Hello'. 'Привет'. '你好'. 'مرحبا' }.

	"lookaround and named capture groups"
	self
		assert: ('\b\w+?(?=\d)' asPCRegex findAll:
				 'not test123 this example456 another789') asArray
		equals: { 'test'. 'example'. 'another' }.
	self
		assert: ('(?<=\d)(?:[^\d]\w+)' asPCRegex findAll:
				 'not 123test this 456example 789another') asArray
		equals: { 'test'. 'example'. 'another' }.
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPCRegex findAll: 'user@example.com admin@domain.org') asArray
		equals: { 'user@example.com'. 'admin@domain.org' }
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindAllWithGroups [

	self
		assert: ('(\w)+' asPCRegex findAllWithGroups: 'hello world') asArray
		equals: #( #( 'hello' 'o' ) #( 'world' 'd' ) ).
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPCRegex findAllWithGroups: 'user@example.com admin@domain.org')
				asArray
		equals: #( #( 'user@example.com' 'user' 'example.com' )
			   #( 'admin@domain.org' 'admin' 'domain.org' ) ).
	self
		assert:
			('([\x{0391}-\x{03C9}])+' asPCRegex findAllWithGroups: 'a-Αλφ-α')
				asArray
		equals: #( #( 'Αλφ' 'φ' ) #( 'α' 'α' ) )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testFindWithGroups [

	self
		assert: ('(\w)+' asPCRegex findWithGroups: 'hello')
		equals: #( 'hello' 'o' ).
	self
		assert:
			('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
				 asPCRegex findWithGroups: 'user@example.com admin@domain.org')
		equals: #( 'user@example.com' 'user' 'example.com' ).
	self
		assert:
		('([\x{0391}-\x{03C9}])+' asPCRegex findWithGroups: 'a-Αλφ-α')
		equals: #( 'Αλφ' 'φ' )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testInfo [

	| regex infoFrameSize infoNameTable infoJITSize |
	regex := '' asPCRegex.

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
	regex := '' asPCRegex.
	self assert: (regex findMatch: '') mark equals: nil.

	regex := '(*MARK:bye)((*MARK:hello)A|D)C' asPCRegex.
	self assert: (regex findMatch: 'AC') mark equals: 'hello'.
	self assert: (regex findMatch: 'DC') mark equals: 'bye'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchLimit [

	| regex |
	regex := '(a+)+' asPCRegex.
	regex context matchLimit: 1.

	self
		should: [ regex matches: 'aa' ]
		raise: PCRE2MatchError
		withExceptionDo: [ :e |
		self assert: e messageText equals: 'match limit exceeded' ]
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatches [

	self assert: ('\d+' asPCRegex matches: '123').
	self assert: ('\w+' asPCRegex matches: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPCRegex
			 matches: 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPCRegex matches: '(123) 456-7890').

	"no match"
	self deny:
		('\d' asPCRegex matches:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self deny: ('[éèêë]' asPCRegex matches: 'café').
	self assert: ('\p{L}+' asPCRegex matches: 'naïve').
	self deny:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPCRegex matches: '€ $ £ ¥').
	self deny:
		('[\x{0391}-\x{03C9}]+' asPCRegex matches: 'Αλφα Βήτα Γάμμα').
	self deny: ('[\x{0400}-\x{04FF}]+' asPCRegex matches: 'Привет мир').
	self deny: ('[\x{1F600}-\x{1F64F}]' asPCRegex matches: '😀😃😄😁').
	self deny:
		('[\x{0600}-\x{06FF}]+' asPCRegex matches: 'مرحبا بالعالم').
	self deny:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPCRegex matches: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self deny: ('\b\w+?(?=\d)' asPCRegex matches:
			 'not test123 this example456 another789').
	self deny: ('(?<=\d)(?:[^\d]\w+)' asPCRegex matches:
			 'not 123test this 456example 789another').
	self deny:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPCRegex matches: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchesInCollect [

	self
		assert: ('\d' asPCRegex
				 matchesIn: '123'
				 collect: [ :match | match asInteger + 1 ]) asArray
		equals: #( 2 3 4 ).

	self
		assert: ('\w' asPCRegex
				 matchesIn: 'hello'
				 collect: [ :match | match first asciiValue ]) asArray
		equals: #( 104 101 108 108 111 ).

	"no match"
	self assert: ('\d' asPCRegex
			 matchesIn: 'the quick brown fox jumps over the lazy dog'
			 collect: [ :match | match ]) isEmpty.

	"variable-length encoding"
	self
		assert: ('[\x{0391}-\x{03C9}]+' asPCRegex
				 matchesIn: 'Αλφα Βήτα Γάμμα'
				 collect: [ :match | match size ]) asArray
		equals: #( 4 4 5 ).

	self
		assert: ('[\x{0400}-\x{04FF}]+' asPCRegex
				 matchesIn: 'Привет мир'
				 collect: [ :match | match size ]) asArray
		equals: #( 6 3 ).

	self
		assert:
			('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
				 asPCRegex
				 matchesIn: 'Hello, Привет, 你好, مرحبا'
				 collect: [ :match | match size ]) asArray
		equals: #( 5 6 2 5 )
]

{ #category : 'tests' }
PCRE2MatcherTest >> testMatchesPrefix [

	self assert: ('\d+' asPCRegex matchesPrefix: '123').
	self assert: ('\w+' asPCRegex matchesPrefix: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPCRegex
			 matchesPrefix: 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPCRegex matchesPrefix: '(123) 456-7890').

	"no match"
	self deny: ('\d' asPCRegex matchesPrefix:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self deny: ('[éèêë]' asPCRegex matchesPrefix: 'café').
	self assert: ('\p{L}+' asPCRegex matchesPrefix: 'naïve').
	self assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPCRegex matchesPrefix: '€ $ £ ¥').
	self assert:
		('[\x{0391}-\x{03C9}]+' asPCRegex matchesPrefix: 'Αλφα Βήτα Γάμμα').
	self assert:
		('[\x{0400}-\x{04FF}]+' asPCRegex matchesPrefix: 'Привет мир').
	self assert:
		('[\x{1F600}-\x{1F64F}]' asPCRegex matchesPrefix: '😀😃😄😁').
	self assert:
		('[\x{0600}-\x{06FF}]+' asPCRegex matchesPrefix: 'مرحبا بالعالم').
	self assert:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPCRegex matchesPrefix: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self deny: ('\b\w+?(?=\d)' asPCRegex matchesPrefix:
			 'not test123 this example456 another789').
	self deny: ('(?<=\d)(?:[^\d]\w+)' asPCRegex matchesPrefix:
			 'not 123test this 456example 789another').
	self assert:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPCRegex matchesPrefix: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testNonASCIIByteStringSubjectIsEncoded [

	| match subject |
	subject := 'café'.
	match := 'é' asPCRegex findMatch: subject.

	self deny: match subject identicalTo: subject.
	self
		assert: match subject
		equals: (ZnUTF8Encoder default encodeString: subject).
	self assert: match decoder class equals: ZnUTF8Encoder.
	self assert: match readMatch equals: 'é'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testRecompile [

	self assert: ('a' asPCRegex finalize recompile matches: 'a')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testSearch [

	self assert: ('\d+' asPCRegex search: '123').
	self assert: ('\w+' asPCRegex search: 'hello').
	self assert:
		('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' asPCRegex search:
			 'user@example.com').
	self assert:
		('\(\d{3}\) \d{3}-\d{4}' asPCRegex search: '(123) 456-7890').

	"no match"
	self deny:
		('\d' asPCRegex search:
			 'the quick brown fox jumps over the lazy dog').

	"variable-length encoding"
	self assert: ('[éèêë]' asPCRegex search: 'café').
	self assert: ('\p{L}+' asPCRegex search: 'naïve').
	self assert:
		('[\x{20AC}\x{00A3}\x{00A5}]' asPCRegex search: '€ $ £ ¥').
	self assert:
		('[\x{0391}-\x{03C9}]+' asPCRegex search: 'Αλφα Βήτα Γάμμα').
	self assert: ('[\x{0400}-\x{04FF}]+' asPCRegex search: 'Привет мир').
	self assert: ('[\x{1F600}-\x{1F64F}]' asPCRegex search: '😀😃😄😁').
	self assert:
		('[\x{0600}-\x{06FF}]+' asPCRegex search: 'مرحبا بالعالم').
	self assert:
		('[a-zA-Z\x{0400}-\x{04FF}\x{4E00}-\x{9FAF}\x{0600}-\x{06FF}]+'
			 asPCRegex search: 'Hello, Привет, 你好, مرحبا').

	"lookaround and named capture groups"
	self assert: ('\b\w+?(?=\d)' asPCRegex search:
			 'not test123 this example456 another789').
	self assert: ('(?<=\d)(?:[^\d]\w+)' asPCRegex search:
			 'not 123test this 456example 789another').
	self assert:
		('(?<username>[a-zA-Z0-9._%+-]+)@(?<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'
			 asPCRegex search: 'user@example.com admin@domain.org')
]

{ #category : 'tests' }
PCRE2MatcherTest >> testStartIndex [

	| regex |
	regex := 'bc' asPCRegex.
	self assert: (regex findMatch: 'abc') startIndex equals: 2
]

{ #category : 'tests' }
PCRE2MatcherTest >> testWithOffsetLimit [

	| regex |
	regex := 'B' asPCRegexWithOptions: PCRE2 useOffsetLimit.
	regex addOptions: PCRE2 substituteGlobal.
	regex context offsetLimit: 6.

	self
		assert: (regex substitute: 'ABC ABC ABC ABC' with: '!')
		equals: 'A!C A!C ABC ABC'
]

{ #category : 'tests' }
PCRE2MatcherTest >> testZeroTerminated [

	| encoder match regex subject utfSubject |
	regex := '.*' asPCRegex.
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
