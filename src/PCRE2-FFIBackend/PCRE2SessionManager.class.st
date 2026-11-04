"
Restores the PCRE2 external objects after an image restart. Compiled patterns are serialized at shutdown, by code-unit width, and deserialized at startup when the library still matches; otherwise they are recompiled from their pattern and options. Other wrappers rebuild their handle from the state they keep.
"
Class {
	#name : 'PCRE2SessionManager',
	#superclass : 'Object',
	#instVars : [
		'matchersToRestore',
		'objectsToRestore',
		'serializedMatchers',
		'serializedSignature'
	],
	#classInstVars : [
		'enabled',
		'instance',
		'useSerialization'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
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
PCRE2SessionManager class >> serializationLibraryForCodeUnitWidth: codeUnitWidth [

	codeUnitWidth = 8 ifTrue: [ ^ LibPCRE2UTF8 ].
	codeUnitWidth = 16 ifTrue: [ ^ LibPCRE2UTF16 ].
	codeUnitWidth = 32 ifTrue: [ ^ LibPCRE2UTF32 ].
	PCRE2Error signal: 'Unsupported PCRE2 serialized code-unit width'
]

{ #category : 'persistence' }
PCRE2SessionManager class >> serializationSignature [
	"Answer the runtime identity that serialized PCRE2 bytecode depends on."

	^ Dictionary newFrom: {
			  (#pcre2Version -> LibPCRE2 versionString).
			  (#endianness -> EndianDetector endianness).
			  (#wordSize -> ExternalAddress wordSize).
			  (#sizeTSize -> FFIArchitecture forCurrentArchitecture sizeTTypeSize).
			  (#compiledWidths -> (LibPCRE2 config: PCRE2 configCompiledWidths)).
			  (#unicode -> LibPCRE2 supportsUnicode) }
]

{ #category : 'asserting' }
PCRE2SessionManager class >> shouldUseSerialization [

	^ useSerialization
]

{ #category : 'system startup' }
PCRE2SessionManager class >> shutDown: quitting [
	"Prepare saved state without invalidating handles in a continuing session."

	enabled ifTrue: [
			instance := self new.
			quitting
				ifTrue: [ instance shutDown ]
				ifFalse: [ instance prepareForSnapshot ] ]
]

{ #category : 'system startup' }
PCRE2SessionManager class >> startUp: resuming [

	resuming ifFalse: [
			instance := nil.
			^ self ].
	enabled ifFalse: [ ^ self ].

	"Failsafe in case restoration crashes the image"
	(OSEnvironment current includesKey: 'PHARO_PCRE2_NOSTARTUP') ifTrue: [ ^ self ].


	instance ifNotNil: [
			instance startUp.
			instance := nil ]
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
PCRE2SessionManager >> cacheMatchers [

	(self class shouldUseSerialization and: [ self hasMatchersToRestore ]) ifFalse: [ ^ self ].
	serializedSignature := self class serializationSignature.
	serializedMatchers := self serializeMatchersByCodeUnitWidth
]

{ #category : 'persistence' }
PCRE2SessionManager >> canDeserializeSerializedMatchers [
	"Serialized PCRE2 bytecode is only a cache. Use it only when the saved runtime signature still matches."

	^ serializedMatchers isNotNil and: [ serializedSignature = self class serializationSignature ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> findMatchersToRestore [

	matchersToRestore := Dictionary new.
	{
		PCRE2UTF8Matcher.
		PCRE2UTF16Matcher.
		PCRE2UTF32Matcher } do: [ :matcherClass |
			matcherClass allInstancesDo: [ :matcher |
					(matcher backend requiresSessionRestore and: [ matcher isNull not ]) ifTrue: [
						(matchersToRestore at: matcher codeUnitWidth ifAbsentPut: [ OrderedCollection new ]) add: matcher prepareForShutdown ] ] ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> findObjectsToRestore [

	objectsToRestore := OrderedCollection new.
	self restorableObjectClasses do: [ :objectClass |
			objectClass allInstancesDo: [ :object |
				(object backend requiresSessionRestore and: [ object isNull not ]) ifTrue: [ objectsToRestore add: object prepareForShutdown ] ] ]
]

{ #category : 'testing' }
PCRE2SessionManager >> hasMatchersToRestore [

	^ matchersToRestore isEmptyOrNil not
]

{ #category : 'persistence' }
PCRE2SessionManager >> matcherGroupsDo: aBlock [
	"aBlock takes a code-unit width and its matchers."

	matchersToRestore ifNotNil: [ matchersToRestore keysAndValuesDo: aBlock ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> prepareForSnapshot [

	self findObjectsToRestore.
	self prepareMatchesForSnapshot.
	self findMatchersToRestore.
	self cacheMatchers
]

{ #category : 'enumerating' }
PCRE2SessionManager >> prepareMatchesForShutdown [
	"Copy each live match into the image, so it needs no native handle after startup."

	{
		PCRE2UTF8Match.
		PCRE2UTF16Match.
		PCRE2UTF32Match } do: [ :matchClass |
			matchClass allInstancesDo: [ :match |
				(match backend requiresSessionRestore and: [ (match isPersistent or: [ match isNull ]) not ]) ifTrue: [
					match prepareForShutdown ] ] ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> prepareMatchesForSnapshot [

	{
		PCRE2UTF8Match.
		PCRE2UTF16Match.
		PCRE2UTF32Match } do: [ :matchClass |
			matchClass allInstancesDo: [ :match |
					(match backend requiresSessionRestore and: [ match isNull not and: [ match resultCode isNotNil ] ]) ifTrue: [
						match cacheForSnapshot ] ] ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> recompileMatchers [

	self matcherGroupsDo: [ :width :matchers | matchers do: [ :matcher | matcher recompile ] ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> restorableObjectClasses [

	^ {
		  PCRE2UTF8CharacterTables.
		  PCRE2UTF16CharacterTables.
		  PCRE2UTF32CharacterTables.
		  PCRE2UTF8JITStack.
		  PCRE2UTF16JITStack.
		  PCRE2UTF32JITStack.
		  PCRE2UTF8ConvertContext.
		  PCRE2UTF16ConvertContext.
		  PCRE2UTF32ConvertContext.
		  PCRE2UTF8CompileContext.
		  PCRE2UTF16CompileContext.
		  PCRE2UTF32CompileContext.
		  PCRE2UTF8MatchContext.
		  PCRE2UTF16MatchContext.
		  PCRE2UTF32MatchContext }
]

{ #category : 'persistence' }
PCRE2SessionManager >> restoreObjects [

	objectsToRestore ifNotNil: [ objectsToRestore do: [ :object | object restoreAfterStartup ] ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> restoreSerializedMatchers [
	"Answer false when the matchers must be recompiled instead."

	self canDeserializeSerializedMatchers ifFalse: [ ^ false ].
	[
		self matcherGroupsDo: [ :width :matchers |
				| bytes |
				bytes := serializedMatchers at: width ifAbsent: [ ^ false ].
				(self class serializationLibraryForCodeUnitWidth: width) restore: matchers from: bytes ] ]
		on: PCRE2Error
		do: [ :ex | ^ false ].
	^ true
]

{ #category : 'persistence' }
PCRE2SessionManager >> serializeMatchersByCodeUnitWidth [

	| serialized |
	serialized := Dictionary new.
	self matcherGroupsDo: [ :width :matchers |
		serialized at: width put: ((self class serializationLibraryForCodeUnitWidth: width) serialize: matchers) ].
	^ serialized
]

{ #category : 'accessing' }
PCRE2SessionManager >> serializedSignature [

	^ serializedSignature
]

{ #category : 'accessing' }
PCRE2SessionManager >> serializedSignature: aDictionary [

	serializedSignature := aDictionary
]

{ #category : 'persistence' }
PCRE2SessionManager >> shutDown [

	self findObjectsToRestore.
	self prepareMatchesForShutdown.
	self findMatchersToRestore.
	self cacheMatchers
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [

	self restoreObjects.
	self hasMatchersToRestore ifFalse: [ ^ self ].

	(self class shouldUseSerialization and: [ self restoreSerializedMatchers ]) ifFalse: [ self recompileMatchers ]
]
