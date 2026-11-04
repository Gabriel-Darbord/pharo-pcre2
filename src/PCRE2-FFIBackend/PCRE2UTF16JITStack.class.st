"
JIT stack of the 16-bit PCRE2 library, for a PCRE2UTF16MatchContext.
"
Class {
	#name : 'PCRE2UTF16JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'memory management' }
PCRE2UTF16JITStack class >> freeUnusedMemory [

	^ LibPCRE2UTF16 jitFreeUnusedMemory
]

{ #category : 'external resource management' }
PCRE2UTF16JITStack >> basicFree [
	"No match context may still point to this stack."

	self ffiCall: #(void pcre2_jit_stack_free_16(self))
]

{ #category : 'private' }
PCRE2UTF16JITStack >> codeUnitWidth [

	^ 16
]

{ #category : 'private' }
PCRE2UTF16JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [

	self ffiCall: #(void *pcre2_jit_stack_create_16(size_t anInitialSize, size_t aMaximumSize, nil))
]

{ #category : 'library path' }
PCRE2UTF16JITStack >> ffiLibraryName [

	^ LibPCRE2UTF16
]
