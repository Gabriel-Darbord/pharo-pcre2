"
Backend-independent context facade. The selected backend owns settings and any external context handle.
"
Class {
	#name : 'PCRE2Context',
	#superclass : 'Object',
	#instVars : [
		'backend'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'backends' }
PCRE2Context >> autoRelease [

	backend autoRelease
]

{ #category : 'backends' }
PCRE2Context >> backend [

	^ backend
]

{ #category : 'backends' }
PCRE2Context >> backend: anImplementation [

	backend ifNotNil: [ PCRE2Error signal: 'Create a new context to select a different backend' ].
	backend := anImplementation
]

{ #category : 'backends' }
PCRE2Context >> codeUnitWidth [

	^ backend codeUnitWidth
]

{ #category : 'backends' }
PCRE2Context >> ffiLibraryName [

	^ backend ffiLibraryName
]

{ #category : 'backends' }
PCRE2Context >> finalize [

	backend finalize
]

{ #category : 'backends' }
PCRE2Context >> free [

	backend free
]

{ #category : 'backends' }
PCRE2Context >> getHandle [

	^ backend getHandle
]

{ #category : 'backends' }
PCRE2Context >> isNull [

	^ backend isNull
]

{ #category : 'backends' }
PCRE2Context >> postCopy [

	backend := backend copy
]

{ #category : 'backends' }
PCRE2Context >> prepareForShutdown [

	backend prepareForShutdown
]
