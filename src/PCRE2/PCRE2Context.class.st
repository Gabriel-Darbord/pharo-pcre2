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

{ #category : 'external resource management' }
PCRE2Context >> autoRelease [

	backend autoRelease
]

{ #category : 'accessing' }
PCRE2Context >> backend [

	^ backend
]

{ #category : 'accessing' }
PCRE2Context >> backend: anImplementation [

	backend ifNotNil: [ PCRE2Error signal: 'Create a new context to select a different backend' ].
	backend := anImplementation
]

{ #category : 'accessing' }
PCRE2Context >> codeUnitWidth [

	^ backend codeUnitWidth
]

{ #category : 'library path' }
PCRE2Context >> ffiLibraryName [

	^ backend ffiLibraryName
]

{ #category : 'finalization' }
PCRE2Context >> finalize [

	backend finalize
]

{ #category : 'external resource management' }
PCRE2Context >> free [

	backend free
]

{ #category : 'private' }
PCRE2Context >> getHandle [

	^ backend getHandle
]

{ #category : 'testing' }
PCRE2Context >> isNull [

	^ backend isNull
]

{ #category : 'copying' }
PCRE2Context >> postCopy [

	backend := backend copy
]

{ #category : 'persistence' }
PCRE2Context >> prepareForShutdown [

	backend prepareForShutdown
]
