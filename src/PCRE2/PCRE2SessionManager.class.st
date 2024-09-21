"
I handle the persistence of `PCRE2Object`s across the Pharo image lifecycle.

"
Class {
	#name : 'PCRE2SessionManager',
	#superclass : 'Object',
	#instVars : [
		'codesToRestore',
		'serializedCodes'
	],
	#classVars : [
		'UseSerialization'
	],
	#classInstVars : [
		'enabled',
		'instance'
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

{ #category : 'system startup' }
PCRE2SessionManager class >> shutDown: quitting [
	"Make all compiled patterns persist between sessions"

	(quitting and: [ enabled ]) ifTrue: [ instance := self new shutDown ]
]

{ #category : 'system startup' }
PCRE2SessionManager class >> startUp: resuming [
	"Restore all compiled patterns using the serialized data from the previous session"

	resuming ifFalse: [ ^ self ].

	"Failsafe to disable pattern restoration if it starts crashing in a loop
	-> investigate all scenarios, fix, and maybe remove this?"
	(enabled not or: [
		 OSEnvironment current includesKey: 'PHARO_PCRE2_NOSTARTUP' ])
		ifTrue: [ ^ self ].

	"The instance has a list of all patterns to restore"
	instance ifNotNil: [
		instance startUp.
		instance := nil "release unique reference to free memory" ]
]

{ #category : 'configuration' }
PCRE2SessionManager class >> useRecompilation [

	<script>
	UseSerialization := false
]

{ #category : 'configuration' }
PCRE2SessionManager class >> useSerialization [

	<script>
	UseSerialization := true
]

{ #category : 'system startup' }
PCRE2SessionManager >> shutDown [
	"Make all compiled patterns persistent between sessions by serializing them.
	Keep strong references to codes to avoid de-/serialization mismatch:
	all serialized codes must still exist for deserialization to succeed.
	This might be changed later to work with weak references if needed.
	A compiled pattern may have a null handle if the image previously crashed,
	not handling it would cause another crash on startup."

	codesToRestore := OrderedCollection new.
	PCRE2Code allInstancesDo: [ :code |
		code isNull ifFalse: [ codesToRestore add: code bePersistent ] ].

	(UseSerialization and: [ codesToRestore isNotEmpty ]) ifTrue: [
		serializedCodes := LibPCRE2 serialize: codesToRestore ]
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [
	"Restore all compiled patterns using the serialized data from the previous session.
	Deserialization does not work if the architecture has changed; TODO add a check."

	codesToRestore isEmptyOrNil ifTrue: [ ^ self ].

	UseSerialization
		ifFalse: [ codesToRestore do: [ :code | code recompile ] ]
		ifTrue: [
			serializedCodes ifNotNil: [
				LibPCRE2 restore: codesToRestore from: serializedCodes ] ]
]
