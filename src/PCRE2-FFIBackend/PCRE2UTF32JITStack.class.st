"
JIT stack of the 32-bit PCRE2 library, for a PCRE2UTF32MatchContext.
"
Class {
	#name : 'PCRE2UTF32JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'memory management' }
PCRE2UTF32JITStack class >> freeUnusedMemory [

	^ LibPCRE2UTF32 jitFreeUnusedMemory
]

{ #category : 'external resource management' }
PCRE2UTF32JITStack >> basicFree [
	"No match context may still point to this stack."

	self ffiCall: #(void pcre2_jit_stack_free_32(self))
]

{ #category : 'private' }
PCRE2UTF32JITStack >> codeUnitWidth [

	^ 32
]

{ #category : 'private' }
PCRE2UTF32JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [

	self ffiCall: #(void *pcre2_jit_stack_create_32(size_t anInitialSize, size_t aMaximumSize, nil))
]

{ #category : 'library path' }
PCRE2UTF32JITStack >> ffiLibraryName [

	^ LibPCRE2UTF32
]
