Class {
	#name : 'PCRE2Object',
	#superclass : 'FFIOpaqueObject',
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2Object class >> fromHandle: aHandle [

	^ self basicNew setHandle: aHandle
]

{ #category : 'testing' }
PCRE2Object class >> isAbstract [

	^ self == PCRE2Object
]

{ #category : 'instance creation' }
PCRE2Object class >> new [

	PCRE2Error signal: 'Must only be instantiated through the API'
]

{ #category : 'external resource management' }
PCRE2Object >> autoRelease [

	FinalizationRegistry default add: self
]

{ #category : 'copying' }
PCRE2Object >> copy [
	"Do not use shallowCopy because of the finalization requirement.
	If either the original or a copy is finalized, the shared structure would be
	freed from memory, leaving the remaining objects in an incorrect state."

	^ self deepCopy
]

{ #category : 'error handling' }
PCRE2Object >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2Error signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'library path' }
PCRE2Object >> ffiLibraryName [

	^ LibPCRE2
]

{ #category : 'finalization' }
PCRE2Object >> finalize [

	self free.
	handle beNull
]

{ #category : 'initialize-release' }
PCRE2Object >> free [

	self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2Object >> initialize [
	"do nothing (prevent initialize to set the handle)"
]
