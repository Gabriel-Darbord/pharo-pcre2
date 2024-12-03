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

	self deny: regex matchData isPersistent.
	self assert: manager serializedMatchers identicalTo: nil.

	manager shutDown.

	self assert: regex matchData isPersistent. "<- this behavior is mocked, still verify that it is correct"
	self assert: manager serializedMatchers identicalTo: nil
]

{ #category : 'tests' }
PCRE2SessionManagerTest >> testShutDownWithSerialization [

	| manager regex |
	PCRE2MockSessionManager useSerialization: true.
	manager := PCRE2MockSessionManager new.
	regex := '' asPCRegex.
	manager matchersToRestore: { regex }.

	self deny: regex matchData isPersistent.
	self assert: manager serializedMatchers identicalTo: nil.

	manager shutDown.

	self assert: regex matchData isPersistent. "<- this behavior is mocked, still verify that it is correct"
	self deny: manager serializedMatchers identicalTo: nil.
	self assert: manager serializedMatchers size equals: 1247
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
