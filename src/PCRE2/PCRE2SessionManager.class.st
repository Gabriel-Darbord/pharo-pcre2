"
Restores compiled PCRE2 matchers after an image restart.

The default strategy serializes matchers at shutdown and deserializes them at startup when the native library signature still matches. The cache is grouped by PCRE2 code-unit width because the 8-bit, 16-bit, and 32-bit libraries deserialize their own compiled patterns.

If the serialized cache is stale or unavailable, the manager falls back to recompiling from the saved pattern and options. This keeps external PCRE2 handles out of normal matcher state while preserving portability across PCRE2 versions and platforms.
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
PCRE2SessionManager class >> serializationLibraryForCodeUnitWidth: codeUnitWidth [
	"Answer the PCRE2 FFI library class for a serialized matcher width."

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
	"Make all compiled patterns persist between sessions"

	quitting & enabled ifTrue: [ instance := self new shutDown ]
]

{ #category : 'system startup' }
PCRE2SessionManager class >> startUp: resuming [
	"Restore all compiled patterns using the serialized data from the previous session"

	resuming & enabled ifFalse: [ ^ self ].

	"Failsafe to disable restoration if it crashes the image (open an issue if this happens!)"
	(OSEnvironment current includesKey: 'PHARO_PCRE2_NOSTARTUP') ifTrue: [ ^ self ].

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

	^ serializedMatchers notNil and: [ serializedSignature = self class serializationSignature ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> findMatchersToRestore [
	"Register all loaded matchers by code-unit width and make them persistent before shutdown serialization."

	matchersToRestore := Dictionary new.
	{
		PCRE2UTF8Matcher.
		PCRE2UTF16Matcher.
		PCRE2UTF32Matcher } do: [ :matcherClass |
			matcherClass allInstancesDo: [ :matcher |
					matcher isNull ifFalse: [
						(matchersToRestore at: matcher codeUnitWidth ifAbsentPut: [ OrderedCollection new ]) add: matcher bePersistent ] ] ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> findObjectsToRestore [
	"Register live external wrappers that can rebuild their native handles after image startup."

	objectsToRestore := OrderedCollection new.
	self restorableObjectClasses do: [ :objectClass |
		objectClass allInstancesDo: [ :object | object isNull ifFalse: [ objectsToRestore add: object bePersistent ] ] ]
]

{ #category : 'testing' }
PCRE2SessionManager >> hasMatchersToRestore [
	"Answer whether at least one matcher must be restored at startup."

	^ matchersToRestore isEmptyOrNil not
]

{ #category : 'persistence' }
PCRE2SessionManager >> matcherGroupsDo: aBlock [
	"Evaluate aBlock with each non-empty code-unit width and matcher collection."

	matchersToRestore ifNotNil: [ matchersToRestore keysAndValuesDo: aBlock ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> persistMatches [
	"Make live match data independent from native match-data handles before shutdown. Matches are Pharo-side snapshots after bePersistent and need no startup restore work."

	{
		PCRE2UTF8Match.
		PCRE2UTF16Match.
		PCRE2UTF32Match } do: [ :matchClass |
		matchClass allInstancesDo: [ :match | (match isPersistent or: [ match isNull ]) ifFalse: [ match bePersistent ] ] ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> recompileMatchers [
	"Portable restore path: rebuild compiled patterns from their Smalltalk-side source of truth."

	self matcherGroupsDo: [ :width :matchers | matchers do: [ :matcher | matcher recompile ] ]
]

{ #category : 'enumerating' }
PCRE2SessionManager >> restorableObjectClasses [
	"Answer concrete PCRE2Object classes whose native handles can be rebuilt from Pharo-side state."

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
	"Rebuild native handles for non-matcher PCRE2Object wrappers captured during shutdown."

	objectsToRestore ifNotNil: [ objectsToRestore do: [ :object | object restore ] ]
]

{ #category : 'persistence' }
PCRE2SessionManager >> restoreSerializedMatchers [
	"Try to restore serialized bytecode caches. Answer true on success, false when startup should recompile instead."

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
	"Answer a dictionary of code-unit width to serialized compiled-pattern bytes."

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

{ #category : 'system startup' }
PCRE2SessionManager >> shutDown [

	self findObjectsToRestore.
	self persistMatches.
	self findMatchersToRestore.
	(self class shouldUseSerialization and: [ self hasMatchersToRestore ]) ifFalse: [ ^ self ].
	serializedSignature := self class serializationSignature.
	serializedMatchers := self serializeMatchersByCodeUnitWidth
]

{ #category : 'system startup' }
PCRE2SessionManager >> startUp [
	"Restore native object wrappers, then restore patterns by trying the serialized bytecode cache first and recompiling when the cache is missing, stale, or rejected by PCRE2."

	self restoreObjects.
	self hasMatchersToRestore ifFalse: [ ^ self ].

	(self class shouldUseSerialization and: [ self restoreSerializedMatchers ]) ifFalse: [ self recompileMatchers ]
]
