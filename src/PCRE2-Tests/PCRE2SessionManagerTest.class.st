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
PCRE2SessionManagerTest >> testShutDownWithRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: false.
	manager := PCRE2MockSessionManager new.
	regex := '' asPCRegex.
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
	regex := '' asPCRegex.
	manager matchersToRestore: { regex }.

	self assert: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedSignature identicalTo: nil.

	manager shutDown.

	self deny: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedMatchers notEmpty.
	self
		assert: manager serializedSignature
		equals: PCRE2MockSessionManager serializationSignature.
	self deny: regex isNull
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithInvalidSerializationFallsBackToRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPCRegex.
	manager matchersToRestore: { regex }.
	manager serializedMatchers: #[ 1 2 3 ].
	manager serializedSignature:
		PCRE2MockSessionManager serializationSignature.

	regex finalize.
	self assert: regex isNull.

	manager startUp.

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testStartUpWithRecompilation [

	| manager regex |
	PCRE2MockSessionManager useSerialization: false.
	manager := PCRE2MockSessionManager new.
	regex := 'a' asPCRegex.
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
	regex := 'a' asPCRegex.
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
	regex := 'a' asPCRegex.
	manager matchersToRestore: { regex }.
	manager serializedMatchers: #[ 1 2 3 ].
	manager serializedSignature:
		(Dictionary newFrom: { (#stale -> true) }).

	regex finalize.
	self assert: regex isNull.

	manager startUp.

	self deny: regex isNull.
	self assert: (regex matches: 'a')
]
