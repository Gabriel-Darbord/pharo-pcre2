"
Abstract superclass for PCRE2 low-character table wrappers.

PCRE2 builds these tables from the process locale with pcre2_maketables(). A compile context can use them to define locale-sensitive behavior for character codes below 256, such as \w, \d, POSIX classes, and caseless matching. Keep the wrapper alive for as long as any compiled pattern may still reference its native table pointer.
"
Class {
	#name : 'PCRE2CharacterTables',
	#superclass : 'PCRE2Object',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2CharacterTables class >> isAbstract [

	^ self == PCRE2CharacterTables
]

{ #category : 'documentation' }
PCRE2CharacterTables >> codeUnitWidth [
	"Answer the PCRE2 library width that allocated these tables."

	^ self ffiLibraryName codeUnitWidth
]

{ #category : 'external resource management' }
PCRE2CharacterTables >> free [
	"Free the native character tables allocated by pcre2_maketables()."

	^ self ffiLibraryName uniqueInstance freeCharacterTables: self
]
