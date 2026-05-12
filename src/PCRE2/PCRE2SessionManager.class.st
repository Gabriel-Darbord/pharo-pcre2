"
I handle the persistence of `PCRE2Object`s across the Pharo image lifecycle.

"
Class {
	#name : 'PCRE2SessionManager',
	#superclass : 'Object',
	#instVars : [
		'matchersToRestore',
		'serializedMatchers',
		'serializedSignature'
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

{ #category : 'persistence' }
PCRE2SessionManager class >> serializationSignature [
	"Answer the runtime identity that serialized PCRE2 bytecode depends on."

	^ Dictionary newFrom: {
			  (#pcre2Version -> LibPCRE2 versionString).
			  (#codeUnitWidth -> 8).
			  (#endianness -> EndianDetector endianness).
			  (#wordSize -> ExternalAddress wordSize).
			  (#sizeTSize
			   -> FFIArchitecture forCurrentArchitecture sizeTTypeSize).
			  (#compiledWidths -> (LibPCRE2 config: PCRE2 configCompiledWidths)).
			  (#unicode -> LibPCRE2 supportsUnicode) }
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

{ #category : 'persistence' }
PCRE2SessionManager >> canDeserializeSerializedMatchers [
	"Serialized PCRE2 bytecode is only a cache. Use it only when the saved runtime signature still matches."

	^ serializedMatchers notNil and: [
		  serializedSignature = self class serializationSignature ]
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

{ #category : 'persistence' }
PCRE2SessionManager >> recompileMatchers [
	"Portable restore path: rebuild compiled patterns from their Smalltalk-side source of truth."

	matchersToRestore do: [ :matcher | matcher recompile ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> restoreSerializedMatchers [
	"Try to restore the serialized bytecode cache. Answer true on success, false when startup should recompile instead."

	self canDeserializeSerializedMatchers ifFalse: [ ^ false ].
	[ LibPCRE2 restore: matchersToRestore from: serializedMatchers ]
		on: PCRE2Error
		do: [ :ex | ^ false ].
	^ true
]

{ #category : 'accessing' }
PCRE2SessionManager >> serializedSignature [

	^ serializedSignature
]

{ #category : 'accessing' }
PCRE2SessionManager >> serializedSignature: aDictionary [

	serializedSignature := aDictionary
]

{ #category : 'system startup' }
PCRE2SessionManager >> shutDown [
	"Make all compiled patterns persistent between sessions. Serialized bytecode is saved as a fast cache; the matchers keep enough state to be recompiled if the cache is incompatible."

	self findMatchersToRestore.
	(self class shouldUseSerialization and: [
		 matchersToRestore isNotEmpty ]) ifTrue: [
		serializedSignature := self class serializationSignature.
		serializedMatchers := LibPCRE2 serialize: matchersToRestore ]
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [
	"Restore patterns by trying the serialized bytecode cache first, then recompiling when the cache is missing, stale, or rejected by PCRE2."

	matchersToRestore isEmptyOrNil ifTrue: [ ^ self ].

	(self class shouldUseSerialization and: [
		 self restoreSerializedMatchers ]) ifFalse: [
		self recompileMatchers ]
]
