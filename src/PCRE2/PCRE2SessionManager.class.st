"
I handle the persistence of `PCRE2Object`s across the Pharo image lifecycle.

"
Class {
	#name : 'PCRE2SessionManager',
	#superclass : 'Object',
	#instVars : [
		'matchersToRestore',
		'serializedMatchers'
	],
	#classInstVars : [
		'enabled',
		'instance',
		'useSerialization'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'configuration' }
PCRE2SessionManager class >> disable [

	<script>
	enabled := false
]

{ #category : 'configuration' }
PCRE2SessionManager class >> enable [

	<script>
	enabled := true
]

{ #category : 'class initialization' }
PCRE2SessionManager class >> initialize [

	self enable.
	self useSerialization.
	SessionManager default registerToolClassNamed: self name
]

{ #category : 'asserting' }
PCRE2SessionManager class >> shouldUseSerialization [

	^ useSerialization
]

{ #category : 'system startup' }
PCRE2SessionManager class >> shutDown: quitting [
	"Make all compiled patterns persist between sessions"

	quitting & enabled ifTrue: [ instance := self new shutDown ]
]

{ #category : 'system startup' }
PCRE2SessionManager class >> startUp: resuming [
	"Restore all compiled patterns using the serialized data from the previous session"

	resuming & enabled ifFalse: [ ^ self ].

	"Failsafe to disable restoration if it crashes the image (open an issue if this happens!)"
	(OSEnvironment current includesKey: 'PHARO_PCRE2_NOSTARTUP') ifTrue: [
		^ self ].

	"The instance has a list of all patterns to restore"
	instance ifNotNil: [
		instance startUp.
		instance := nil "release unique reference to free memory" ]
]

{ #category : 'configuration' }
PCRE2SessionManager class >> useRecompilation [

	<script>
	useSerialization := false
]

{ #category : 'configuration' }
PCRE2SessionManager class >> useSerialization [

	<script>
	useSerialization := true
]

{ #category : 'enumerating' }
PCRE2SessionManager >> findMatchersToRestore [
	"Register all matchers and make them persistent.
	This is a hook used by tests to avoid registering all instances."

	matchersToRestore := OrderedCollection new.
	PCRE2Matcher allInstancesDo: [ :matcher |
		matcher isNull ifFalse: [
			matchersToRestore add: matcher bePersistent ] ]
]

{ #category : 'system startup' }
PCRE2SessionManager >> shutDown [
	"Make all compiled patterns persistent between sessions.
	Keep strong references to codes to avoid de-/serialization mismatch:
	all serialized codes must still exist for deserialization to succeed.
	A compiled pattern may have a null handle if the image previously crashed,
	not handling it would cause another crash on startup."

	self findMatchersToRestore.
	(self class shouldUseSerialization and: [ matchersToRestore isNotEmpty ])
		ifTrue: [ serializedMatchers := LibPCRE2 serialize: matchersToRestore ]
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [
	"Restore patterns by recompiling or using serialized data from a previous session.
	Deserialization does not work if serialization was done on a different architecture.
	TODO: Add a way to check for incompatible architectures (can use PCRE2>>#configJITTarget)."

	matchersToRestore isEmptyOrNil ifTrue: [ ^ self ].

	self class shouldUseSerialization
		ifFalse: [ matchersToRestore do: [ :matcher | matcher recompile ] ]
		ifTrue: [
			serializedMatchers ifNotNil: [
				LibPCRE2 restore: matchersToRestore from: serializedMatchers ] ]
]
