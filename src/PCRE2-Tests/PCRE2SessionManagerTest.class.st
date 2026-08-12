"
Tests for image lifecycle restoration of compiled PCRE2 matchers.

The suite covers serialization, deserialization fallback, recompilation fallback, and stale native-library signatures.
"
Class {
	#name : 'PCRE2SessionManagerTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2SessionManagerTest >> testClassSideConfigurationToggles [

	| original |
	original := PCRE2SessionManager shouldUseSerialization.

	[
		PCRE2SessionManager useRecompilation.
		self deny: PCRE2SessionManager shouldUseSerialization.
		PCRE2SessionManager useSerialization.
		self assert: PCRE2SessionManager shouldUseSerialization ] ensure: [
			original
				ifTrue: [ PCRE2SessionManager useSerialization ]
				ifFalse: [ PCRE2SessionManager useRecompilation ] ]
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testMatcherSerializationConvenienceRoundTrip [

	| bytes regex |
	regex := 'a+' asPerlCompatibleRegex.
	bytes := regex serialize.

	regex finalize.
	self assert: regex isNull.
	regex restoreFrom: bytes.

	self deny: regex isNull.
	self assert: (regex matches: 'aaa')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testShutDownPersistsMatches [

	| manager match regex |
	PCRE2MockSessionManager useSerialization: false.
	manager := PCRE2MockSessionManager new.
	regex := '(?<word>\w+)' asPerlCompatibleRegex.
	match := regex findMatch: 'hello'.

	self deny: match isPersistent.
	self deny: match isNull.

	manager shutDown.

	self assert: match isPersistent.
	self assert: match isNull.
	self assert: match readMatch equals: 'hello'.
	self assert: (match groupNamed: 'word') equals: 'hello'
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testShutDownWithRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: false.
	manager := PCRE2MockSessionManager new.
	regex := '' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.

	self assert: manager serializedMatchers identicalTo: nil.

	manager shutDown.

	self assert: manager serializedMatchers identicalTo: nil.
	self deny: regex isNull
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testShutDownWithSerialization [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := '' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.

	self assert: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedSignature identicalTo: nil.

	manager shutDown.

	self deny: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedMatchers notEmpty.
	self assert: manager serializedSignature equals: PCRE2MockSessionManager serializationSignature.
	self deny: regex isNull
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresCharacterTablesFromPersistedBytes [

	| bytes manager restoredBytes tables |
	manager := PCRE2MockSessionManager new.
	tables := LibPCRE2UTF8 newCharacterTables.
	bytes := tables copyBytesFromNativeTable.
	manager objectsToRestore: { tables }.
	tables finalize.
	self assert: tables isNull.

	manager startUp.

	self deny: tables isNull.
	restoredBytes := tables copyBytesFromNativeTable.
	self assert: restoredBytes equals: bytes
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresCompileContext [

	| manager context |
	manager := PCRE2MockSessionManager new.
	context := PCRE2Compiler new context.
	context newline: PCRE2 newlineCR.
	context parensNestLimit: 20.
	context maxPatternLength: 100.
	manager objectsToRestore: { context }.
	context finalize.
	self assert: context isNull.

	manager startUp.

	self deny: context isNull.
	self assert: context newline equals: PCRE2 newlineCR.
	self assert: context parensNestLimit equals: 20.
	self assert: context maxPatternLength equals: 100
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresConvertContext [

	| manager context |
	LibPCRE2 supportsPatternConversion ifFalse: [ self skip ].
	manager := PCRE2MockSessionManager new.
	context := LibPCRE2UTF8 newConvertContext.
	context globEscape: $!.
	context globSeparator: $/.
	manager objectsToRestore: { context }.
	context finalize.
	self assert: context isNull.

	manager startUp.

	self deny: context isNull.
	self assert: context globEscape equals: $! asciiValue.
	self assert: context globSeparator equals: $/ asciiValue
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresJITStack [

	| manager stack |
	LibPCRE2 supportsJIT ifFalse: [ self skip ].
	manager := PCRE2MockSessionManager new.
	stack := PCRE2JITStack startSize: 1024 maxSize: 2048.
	manager objectsToRestore: { stack }.
	stack finalize.
	self assert: stack isNull.

	manager startUp.

	self deny: stack isNull.
	self assert: stack startSize equals: 1024.
	self assert: stack maxSize equals: 2048
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresMatchContextCallout [

	| manager regex context count |
	manager := PCRE2MockSessionManager new.
	regex := '(?C1)a' asPerlCompatibleRegex.
	context := regex context.
	count := 0.
	context calloutBlock: [ :event |
			count := count + 1.
			0 ].
	manager objectsToRestore: { context }.
	context finalize.
	self assert: context isNull.

	manager startUp.

	self deny: context isNull.
	self assert: (regex matches: 'a').
	self assert: count equals: 1
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresMatchContextSubstituteCallout [

	| manager regex context count result |
	LibPCRE2 supportsSubstitutionCallouts ifFalse: [ self skip ].
	manager := PCRE2MockSessionManager new.
	regex := '\w+' asPerlCompatibleRegex.
	context := regex context.
	count := 0.
	context substituteCalloutBlock: [ :event |
			count := count + 1.
			PCRE2 substituteCalloutAccept ].
	manager objectsToRestore: { context }.
	context finalize.
	self assert: context isNull.

	manager startUp.

	self deny: context isNull.
	result := regex substituteAll: 'one two' with: '[$0]'.
	self assert: result equals: '[one] [two]'.
	self assert: count > 0
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpRestoresMatchContextSubstituteCaseCallout [

	| manager regex context count result |
	LibPCRE2 supportsSubstitutionCaseCallouts ifFalse: [ self skip ].
	manager := PCRE2MockSessionManager new.
	regex := '(\w+)' asPerlCompatibleRegex.
	context := regex context.
	count := 0.
	context substituteCaseCalloutBlock: [ :event |
			count := count + 1.
			event inputText reversed ].
	manager objectsToRestore: { context }.
	context finalize.
	self assert: context isNull.

	manager startUp.

	self deny: context isNull.
	result := regex substitute: 'one two' with: '\U$0' options: PCRE2 substituteExtended | PCRE2 substituteGlobal.
	self assert: result equals: 'eno owt'.
	self assert: count equals: 2
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithInvalidSerializationFallsBackToRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.
	manager serializedMatchers: (Dictionary newFrom: { (regex codeUnitWidth -> #[ 1 2 3 ]) }).
	manager serializedSignature: PCRE2MockSessionManager serializationSignature.

	regex finalize.
	self assert: regex isNull.

	manager startUp.

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithMixedWidthSerialization [

	| manager utf8 utf16 utf32 |
	(LibPCRE2 supports16BitCodeUnitWidth and: [ LibPCRE2 supports32BitCodeUnitWidth ]) ifFalse: [ self skip ].

	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	utf8 := 'a+' asPerlCompatibleRegex.
	utf16 := PCRE2UTF16Compiler new compile: 'é+'.
	utf32 := PCRE2UTF32Compiler new compile: 'b+'.
	manager matchersToRestore: {
			utf8.
			utf16.
			utf32 }.

	manager shutDown.
	self assert: (manager serializedMatchers includesKey: 8).
	self assert: (manager serializedMatchers includesKey: 16).
	self assert: (manager serializedMatchers includesKey: 32).

	{
		utf8.
		utf16.
		utf32 } do: [ :matcher | matcher finalize ].
	self assert: utf8 isNull.
	self assert: utf16 isNull.
	self assert: utf32 isNull.

	manager startUp.
	self assert: (utf8 matches: 'aaa').
	self assert: (utf16 matches: 'éé').
	self assert: (utf32 matches: 'bbb')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithNoMatchersDoesNothing [

	| manager |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.

	manager startUp.

	self assert: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedSignature identicalTo: nil
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: false.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.

	self deny: regex isNull.

	"mock a session shutdown"
	regex finalize.

	self assert: regex isNull.

	manager startUp. "recompilation"

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithSerialization [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.

	self deny: regex isNull.

	"mock a session shutdown"
	manager shutDown. "serialization happens"
	regex finalize.

	self assert: regex isNull.

	manager startUp. "deserialization"

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithStaleSerializationFallsBackToRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPerlCompatibleRegex.
	manager matchersToRestore: { regex }.
	manager serializedMatchers: #[ 1 2 3 ].
	manager serializedSignature: (Dictionary newFrom: { (#stale -> true) }).

	regex finalize.
	self assert: regex isNull.

	manager startUp.

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]
