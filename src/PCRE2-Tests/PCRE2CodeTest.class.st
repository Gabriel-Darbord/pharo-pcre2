Class {
	#name : 'PCRE2CodeTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'asserting' }
PCRE2CodeTest >> assertRegex: pattern matchPersists: subject [

	| regex matchData expected |
	regex := pattern asPCRegex.
	regex find: subject.
	matchData := regex matchData.
	self deny: matchData isPersistent. "should not be persistent after a match,
	this can fail if you are debugging the test and restarted the image inbetween"
	expected := matchData readMatch: subject. "original match data result is the oracle"

	regex bePersistent.

	self assert: matchData isPersistent.
	self assert: (matchData readMatch: subject) equals: expected
]

{ #category : 'tests' }
PCRE2CodeTest >> testBePersistent [

	self
		assertRegex: '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
		matchPersists: 'user@example.com'.

	"no match"
	self
		assertRegex: '\d'
		matchPersists: 'glib jocks quiz nymph to vex dwarf'.

	"variable-length encoding"
	self
		assertRegex: '[\x{20AC}\x{00A3}\x{00A5}]'
		matchPersists: '€ $ £ ¥'.

	"lookaround"
	self
		assertRegex: '\b\w+?(?=\d)'
		matchPersists: 'not test123 this example456 another789'

	"TODO named capture groups"
]

{ #category : 'tests' }
PCRE2CodeTest >> testCoolStuff [
	"Some cool stuff that can be done with PCRE"

	| regex |
	"recursive pattern"
	regex := '{((?>[^{}]+|(?R))*)}' asPCRegex.
	self
		assert: (regex findAll: '{1, {2, {3}}} {4, 5}') asArray
		equals: { '{1, {2, {3}}}'. '{4, 5}' }
]

{ #category : 'tests' }
PCRE2CodeTest >> testCopy [

	| regex copy |
	regex := 'a' asPCRegex.
	copy := regex deepCopy.

	"structural equality"
	self deny: regex identicalTo: copy.
	self assert: regex options identicalTo: copy options.
	regex isJIT ifTrue: [ self assert: copy isJIT ].

	"match result equality"
	self assert: (regex find: 'a') equals: (copy find: 'a')
]

{ #category : 'tests' }
PCRE2CodeTest >> testCopyTranslatingMatchesUsing [

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
		equals: 'b_a_b_a_b'
]

{ #category : 'tests' }
PCRE2CodeTest >> testFind [

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
PCRE2CodeTest >> testFindAll [

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
PCRE2CodeTest >> testMark [

	| regex |
	regex := '' asPCRegex.
	regex find: ''.
	self assert: regex mark equals: nil.

	regex := '(*MARK:bye)((*MARK:hello)A|D)C' asPCRegex.
	regex find: 'AC'.
	self assert: regex mark equals: 'hello'.
	regex find: 'DC'.
	self assert: regex mark equals: 'bye'
]

{ #category : 'tests' }
PCRE2CodeTest >> testMatches [

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
PCRE2CodeTest >> testSearch [

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
PCRE2CodeTest >> testStartIndex [

	| regex |
	regex := 'bc' asPCRegex.
	regex find: 'abc'.
	self assert: regex startIndex equals: 2
]

{ #category : 'tests' }
PCRE2CodeTest >> testWithOffsetLimit [

	| regex |
	self flag: #TODO. "something weird here, useOffsetLimit is not for substitute, don't use substitute to test this"
	regex := 'B' asPCRegexWithOptions: PCRE2 useOffsetLimit.
	regex addOptions: PCRE2 substituteGlobal.
	regex context offsetLimit: 12.

	self
		assert: (regex substitute: 'ABC ABC ABC ABC' with: '!')
		equals: 'A!C A!C A!C ABC'
]
