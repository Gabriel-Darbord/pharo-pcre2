"
Abstract superclass for PCRE2 JIT stack wrappers.

JIT stacks are an advanced performance knob for large or complex JIT-compiled patterns that exceed PCRE2's default runtime stack. A stack is owned by Pharo code and can be assigned to a match context; PCRE2 only stores a raw pointer, so the stack must stay alive while any assigned context may be used for matching.

Use one stack only for sequential matches in one thread. Concurrent or nested matches need separate stacks.
"
Class {
	#name : 'PCRE2JITStack',
	#superclass : 'PCRE2Object',
	#instVars : [
		'startSize',
		'maxSize'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'instance creation' }
PCRE2JITStack class >> default [
	"Answer a JIT stack with PCRE2's commonly recommended maximum size."

	^ self startSize: self defaultStartSize maxSize: self defaultMaxSize
]

{ #category : 'defaults' }
PCRE2JITStack class >> defaultMaxSize [
	"Default maximum JIT stack size. PCRE2 documents 512 KiB to 1 MiB as enough for almost all patterns."

	^ 1024 * 1024
]

{ #category : 'defaults' }
PCRE2JITStack class >> defaultStartSize [
	"Default initial JIT stack reservation, matching PCRE2's built-in stack size."

	^ 32 * 1024
]

{ #category : 'memory management' }
PCRE2JITStack class >> freeUnusedMemory [
	"Ask the PCRE2 JIT allocator to release speculative executable memory for this code-unit library."

	self == PCRE2JITStack ifTrue: [ ^ PCRE2UTF8JITStack freeUnusedMemory ].
	^ self subclassResponsibility
]

{ #category : 'testing' }
PCRE2JITStack class >> isAbstract [

	^ self == PCRE2JITStack
]

{ #category : 'instance creation' }
PCRE2JITStack class >> startSize: startSize maxSize: maxSize [
	"Create a JIT stack. Sending this to PCRE2JITStack itself creates the UTF-8 variant, matching the default compiler."

	| stack |
	self == PCRE2JITStack ifTrue: [
		^ PCRE2UTF8JITStack startSize: startSize maxSize: maxSize ].
	stack := self basicNew.
	stack initializeWithStartSize: startSize maxSize: maxSize.
	^ stack autoRelease
]

{ #category : 'private' }
PCRE2JITStack >> codeUnitWidth [

	^ self subclassResponsibility
]

{ #category : 'private' }
PCRE2JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [

	^ self subclassResponsibility
]

{ #category : 'initialization' }
PCRE2JITStack >> initializeWithStartSize: anInitialSize maxSize: aMaximumSize [
	"Allocate the native JIT stack and remember the requested bounds for inspection."

	(anInitialSize isInteger and: [ aMaximumSize isInteger ]) ifFalse: [
		PCRE2Error signal: 'JIT stack sizes must be integers' ].
	(anInitialSize < 0 or: [ aMaximumSize < anInitialSize ]) ifTrue: [
		PCRE2Error signal:
			'JIT stack sizes must be non-negative and ordered' ].
	startSize := anInitialSize.
	maxSize := aMaximumSize.
	handle := self createWithStartSize: startSize maxSize: maxSize.
	handle isNull ifTrue: [
		PCRE2Error signal: 'Failed to obtain memory to create JIT stack' ].
	^ self
]

{ #category : 'accessing' }
PCRE2JITStack >> maxSize [

	^ maxSize
]

{ #category : 'accessing' }
PCRE2JITStack >> startSize [

	^ startSize
]
