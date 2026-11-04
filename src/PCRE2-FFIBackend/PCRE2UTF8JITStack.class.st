"
JIT stack of the 8-bit PCRE2 library, for a PCRE2UTF8MatchContext.
"
Class {
	#name : 'PCRE2UTF8JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'memory management' }
PCRE2UTF8JITStack class >> freeUnusedMemory [

	^ LibPCRE2UTF8 jitFreeUnusedMemory
]

{ #category : 'external resource management' }
PCRE2UTF8JITStack >> basicFree [
	"No match context may still point to this stack."

	self ffiCall: #(void pcre2_jit_stack_free_8(self))
]

{ #category : 'private' }
PCRE2UTF8JITStack >> codeUnitWidth [

	^ 8
]

{ #category : 'private' }
PCRE2UTF8JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [

	self ffiCall: #(void *pcre2_jit_stack_create_8(size_t anInitialSize, size_t aMaximumSize, nil))
]

{ #category : 'library path' }
PCRE2UTF8JITStack >> ffiLibraryName [

	^ LibPCRE2UTF8
]
