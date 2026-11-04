"
Abstract superclass of the low-character tables that PCRE2 builds from the process locale. A compile context uses them for character codes below 256: \w, \d, POSIX classes and caseless matching. Keep them alive while a compiled pattern may reference them; they are saved with the image as bytes, so a restarted image does not depend on its locale.
"
Class {
	#name : 'PCRE2CharacterTables',
	#superclass : 'PCRE2Object',
	#instVars : [
		'persistedBytes',
		'usesPCRE2Allocator'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'testing' }
PCRE2CharacterTables class >> isAbstract [

	^ self == PCRE2CharacterTables
]

{ #category : 'constants' }
PCRE2CharacterTables class >> tableByteSize [
	"PCRE2 serializes one copy of low-character tables as 1088 bytes."

	^ 1088
]

{ #category : 'external resource management' }
PCRE2CharacterTables >> basicFree [
	"Free the native character tables according to the allocator that produced them."

	usesPCRE2Allocator
		ifTrue: [ self ffiLibraryName uniqueInstance freeCharacterTables: self ]
		ifFalse: [ handle free ]
]

{ #category : 'documentation' }
PCRE2CharacterTables >> codeUnitWidth [

	^ self ffiLibraryName codeUnitWidth
]

{ #category : 'private' }
PCRE2CharacterTables >> copyBytesFromNativeTable [

	| bytes |
	self isNull ifTrue: [ PCRE2Error signal: 'Cannot copy bytes from null character tables' ].
	bytes := ByteArray new: self class tableByteSize.
	1 to: bytes size do: [ :index | bytes at: index put: (handle uint8AtOffset: index - 1) ].
	^ bytes
]

{ #category : 'private' }
PCRE2CharacterTables >> copyPersistedBytesToNativeMemory [
	"The caller owns the answered memory."

	| pointer |
	self validatePersistedBytes.
	pointer := ExternalAddress allocate: persistedBytes size.
	pointer isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to restore character tables' ].
	1 to: persistedBytes size do: [ :index | pointer uint8AtOffset: index - 1 put: (persistedBytes at: index) ].
	^ pointer
]

{ #category : 'initialization' }
PCRE2CharacterTables >> initialize [

	super initialize.
	usesPCRE2Allocator := true
]

{ #category : 'persistence' }
PCRE2CharacterTables >> prepareForShutdown [
	"Snapshot my native table bytes so restore does not depend on the current process locale."

	self isNull ifFalse: [ persistedBytes := self copyBytesFromNativeTable ]
]

{ #category : 'persistence' }
PCRE2CharacterTables >> restoreAfterStartup [
	"Recreate low-character tables from persisted bytes when available, otherwise from the current process locale."

	persistedBytes
		ifNil: [
				self setHandle: self ffiLibraryName uniqueInstance makeCharacterTables.
				usesPCRE2Allocator := true ]
		ifNotNil: [
				self setHandle: self copyPersistedBytesToNativeMemory.
				usesPCRE2Allocator := false ].
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore character tables' ]
]

{ #category : 'private' }
PCRE2CharacterTables >> validatePersistedBytes [

	persistedBytes size = self class tableByteSize ifFalse: [
		PCRE2Error signal: 'Persisted character tables have an invalid byte size' ]
]
