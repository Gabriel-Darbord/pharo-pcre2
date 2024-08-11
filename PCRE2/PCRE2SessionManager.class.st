Class {
	#name : 'PCRE2SessionManager',
	#superclass : 'Object',
	#instVars : [
		'codesToRestore',
		'serializedCodes'
	],
	#classVars : [
		'Enabled',
		'Instance'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'protocol' }
PCRE2SessionManager class >> disable [

	<script>
	Enabled := false
]

{ #category : 'protocol' }
PCRE2SessionManager class >> enable [

	<script>
	Enabled := true
]

{ #category : 'class initialization' }
PCRE2SessionManager class >> initialize [

	self enable.
	SessionManager default registerToolClassNamed: self name
]

{ #category : 'system startup' }
PCRE2SessionManager class >> shutDown: quitting [
	"Make all compiled patterns persist between sessions by serializing them"

	(quitting and: [ Enabled ]) ifTrue: [ Instance := self new shutDown ]
]

{ #category : 'system startup' }
PCRE2SessionManager class >> startUp: resuming [
	"Restore all compiled patterns using the serialized data from the previous session"

	resuming ifFalse: [ ^ self ].

	"Failsafe to disable pattern restoration if it starts crashing in a loop
	-> investigate all scenarios, fix, and maybe remove this?"
	OSEnvironment current
		at: 'PHARO_PCRE2_NOPERSIST'
		ifPresent: [ :_ | Enabled := false ].

	"The instance has a list of all patterns to restore and the serialized data"
	(Enabled and: [ Instance isNotNil ]) ifTrue: [ Instance startUp ].
	Instance := nil "release unique reference to free memory"
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

	codesToRestore ifNotEmpty: [
		serializedCodes := LibPCRE2 serialize: codesToRestore ]
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [
	"Restore all compiled patterns using the serialized data from the previous session.
	Deserialization does not work if the architecture has changed; TODO add a check."

	(serializedCodes isNil or: [ codesToRestore isEmptyOrNil ]) ifFalse: [
		LibPCRE2 restore: codesToRestore from: serializedCodes ]
]
