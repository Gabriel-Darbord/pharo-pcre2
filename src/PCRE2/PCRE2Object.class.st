"
Abstract superclass of all PCRE2 external object wrappers.
Wrappers automatically free the memory of their external object on finalization.
Making a `copy` will allocate a new external object.
A `clone` will share its reference with the original. This means that if one is garbage-collected and the other is used, the image will crash due to a segmentation fault.
For a `PCRE2Code`, this happens if the pattern is JIT-compiled *and* the JIT fast path is enabled.

Using `shallowCopy` directly makes the copy use the same external object.
If either the original or a copy is finalized, the shared object will be freed from memory, leaving the remaining objects in an incorrect state.
"
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
