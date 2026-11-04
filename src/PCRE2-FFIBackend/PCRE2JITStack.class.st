"
Abstract superclass of the JIT stacks, which a match context uses when a JIT-compiled pattern needs more stack than PCRE2's default. PCRE2 keeps only a pointer, so a stack must outlive every context it is assigned to. A stack serves one match at a time: concurrent or nested matches need separate stacks.
"
Class {
	#name : 'PCRE2JITStack',
	#superclass : 'PCRE2Object',
	#instVars : [
		'startSize',
		'maxSize'
	],
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'instance creation' }
PCRE2JITStack class >> default [
	"Answer a JIT stack with PCRE2's commonly recommended maximum size."

	^ self startSize: self defaultStartSize maxSize: self defaultMaxSize
]

{ #category : 'defaults' }
PCRE2JITStack class >> defaultMaxSize [
	"PCRE2 documents 512 KiB to 1 MiB as enough for almost all patterns."

	^ 1024 * 1024
]

{ #category : 'defaults' }
PCRE2JITStack class >> defaultStartSize [
	"The size of PCRE2's built-in stack."

	^ 32 * 1024
]

{ #category : 'memory management' }
PCRE2JITStack class >> freeUnusedMemory [
	"Ask the PCRE2 JIT allocator to release speculative executable memory for this code-unit library."

	self subclassResponsibility
]

{ #category : 'testing' }
PCRE2JITStack class >> isAbstract [

	^ self == PCRE2JITStack
]

{ #category : 'instance creation' }
PCRE2JITStack class >> startSize: startSize maxSize: maxSize [
	"Sizes are in bytes. Sent to PCRE2JITStack itself, answer a UTF-8 stack, the default width."

	| stack |
	self == PCRE2JITStack ifTrue: [ ^ PCRE2UTF8JITStack startSize: startSize maxSize: maxSize ].
	stack := self basicNew.
	stack initializeWithStartSize: startSize maxSize: maxSize.
	^ stack autoRelease
]

{ #category : 'private' }
PCRE2JITStack >> codeUnitWidth [

	self subclassResponsibility
]

{ #category : 'private' }
PCRE2JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [

	self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2JITStack >> initializeWithStartSize: anInitialSize maxSize: aMaximumSize [

	(anInitialSize isInteger and: [ aMaximumSize isInteger ]) ifFalse: [ PCRE2Error signal: 'JIT stack sizes must be integers' ].
	(anInitialSize < 0 or: [ aMaximumSize < anInitialSize ]) ifTrue: [
		PCRE2Error signal: 'JIT stack sizes must be non-negative and ordered' ].
	startSize := anInitialSize.
	maxSize := aMaximumSize.
	handle := self createWithStartSize: startSize maxSize: maxSize.
	handle isNull ifTrue: [ PCRE2Error signal: 'Failed to obtain memory to create JIT stack' ]
]

{ #category : 'accessing' }
PCRE2JITStack >> maxSize [

	^ maxSize
]

{ #category : 'persistence' }
PCRE2JITStack >> restoreAfterStartup [
	"Recreate my native JIT stack from the remembered size bounds."

	self setHandle: (self createWithStartSize: startSize maxSize: maxSize).
	self isNull ifTrue: [ PCRE2Error signal: 'Failed to restore JIT stack' ]
]

{ #category : 'accessing' }
PCRE2JITStack >> startSize [

	^ startSize
]
