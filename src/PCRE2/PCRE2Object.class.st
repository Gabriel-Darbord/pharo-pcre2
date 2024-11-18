"
Abstract superclass of all PCRE2 external object wrappers.
Wrappers automatically free the memory of their external object on finalization.

Making a `copy` will correctly allocate a new external object.

Using `shallowCopy` directly makes the copy use the same external object.
Similarly, a `clone` will share its reference with the original.
When either the original or a copy is finalized, the shared object is freed from memory, leaving the remaining objects in an incorrect state.
The image can even crash due to a segmentation fault.
For example, this happens with a `PCRE2Code' that has a freed external object.
If the pattern is JIT-compiled *and* the JIT fast path is enabled, it will crash when trying to match.
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

{ #category : 'external resource management' }
PCRE2Object >> free [

	self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2Object >> initialize [
	"do nothing (prevent initialize to set the handle)"
]
