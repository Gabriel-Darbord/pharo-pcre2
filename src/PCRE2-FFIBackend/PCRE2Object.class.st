"
Abstract superclass of the wrappers of PCRE2 external objects, which free their object on finalization. `copy` allocates a new external object, but `shallowCopy` and `clone` share it: once either side is finalized, the other holds freed memory, and using it can crash the VM, for example when matching with a JIT-compiled `PCRE2Matcher`.
"
Class {
	#name : 'PCRE2Object',
	#superclass : 'FFIOpaqueObject',
	#pools : [
		'PCRE2Types'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
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

{ #category : 'accessing' }
PCRE2Object >> backend [

	^ self
]

{ #category : 'external resource management' }
PCRE2Object >> basicFree [
	"Called only by free, which checks the handle first and nulls it afterwards."

	self subclassResponsibility
]

{ #category : 'accessing' }
PCRE2Object >> codeUnitWidth [

	^ self ffiLibraryName codeUnitWidth
]

{ #category : 'error handling' }
PCRE2Object >> errorCode: errorCode [

	<debuggerCompleteToSender>
	PCRE2Error signal: (PCRE2 translateErrorCode: errorCode)
]

{ #category : 'accessing' }
PCRE2Object >> family [

	^ #ffi
]

{ #category : 'library path' }
PCRE2Object >> ffiLibraryName [

	self subclassResponsibility
]

{ #category : 'finalization' }
PCRE2Object >> finalize [

	self free
]

{ #category : 'external resource management' }
PCRE2Object >> free [
	"Free the external object and null the handle. Every guard asks isNull, so a handle left on freed memory would let reads through, and a second free would crash.
	Subclasses implement basicFree, not this."

	self isNull ifTrue: [ ^ self ].
	self basicFree.
	handle beNull
]

{ #category : 'initialization' }
PCRE2Object >> initialize [
	"Do not create a handle: instances get theirs from fromHandle:."
]

{ #category : 'private - FFI' }
PCRE2Object >> newCallbackWithSignature: signature block: aBlock [
	"Answer a callback owned by the library of the receiver. A callback runs with the runner of its library, which must be the runner of the callout that triggers it: bound to no library, it runs on the same thread while the library calls out on the worker of the process, and the VM crashes."

	^ FFICallback new
		  ffiLibrary: self ffiLibraryName;
		  signature: signature block: aBlock;
		  yourself
]

{ #category : 'persistence' }
PCRE2Object >> prepareForShutdown [
	"Subclasses copy into the image any state that only the native object holds."

	^ self
]

{ #category : 'testing' }
PCRE2Object >> requiresSessionRestore [

	^ true
]

{ #category : 'persistence' }
PCRE2Object >> restoreAfterStartup [

	self subclassResponsibility
]
