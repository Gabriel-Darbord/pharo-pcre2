"
Abstract superclass of all PCRE2 external object wrappers.
Wrappers automatically free the memory of their external object on finalization.

Making a `copy` will correctly allocate a new external object.

Using `shallowCopy` directly makes the copy use the same external object.
Similarly, a `clone` will share its reference with the original.
When either the original or a copy is finalized, the shared object is freed from memory, leaving the remaining objects in an incorrect state.
The image can even crash due to a segmentation fault.
For example, this happens with a `PCRE2Matcher` that has a freed external object.
If the pattern is JIT-compiled *and* the JIT fast path is enabled, it will crash when trying to match.
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
	"Hand this object's memory back to the library. Called by free, which has already checked the handle and nulls it afterwards."

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
	"Free the external object and leave the handle null.

	Nulling is the point. isNull is what every guard in the library asks before it touches an external object, and a handle that still carries the address of freed memory makes that question answer wrongly: the guard waves the object through and the read goes to memory the allocator has taken back. Freeing twice is also a crash, and the null is what makes the second free a no-op.

	basicFree is the call to the library. Subclasses implement that, not this."

	self isNull ifTrue: [ ^ self ].
	self basicFree.
	handle beNull
]

{ #category : 'initialization' }
PCRE2Object >> initialize [
	"Do nothing (prevent initialize to set the handle)"
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
	"Prepare this wrapper to survive image save/load. Subclasses with native-derived Pharo-side state should materialize it before session shutdown."

	^ self
]

{ #category : 'testing' }
PCRE2Object >> requiresSessionRestore [

	^ true
]

{ #category : 'persistence' }
PCRE2Object >> restoreAfterStartup [
	"Restore the native handle after image startup."

	self subclassResponsibility
]
