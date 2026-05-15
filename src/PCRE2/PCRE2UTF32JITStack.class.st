"
JIT stack wrapper for PCRE2's 32-bit code-unit API.

Instances are explicit advanced resources. Assign one to a PCRE2UTF32MatchContext when a JIT-compiled pattern needs more runtime stack than PCRE2's default.
"
Class {
	#name : 'PCRE2UTF32JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'memory management' }
PCRE2UTF32JITStack class >> freeUnusedMemory [

	^ LibPCRE2UTF32 jitFreeUnusedMemory
]

{ #category : 'private' }
PCRE2UTF32JITStack >> codeUnitWidth [

	^ 32
]

{ #category : 'private' }
PCRE2UTF32JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [
	"Create a JIT stack for libpcre2-32."

	self ffiCall:
		#( void #* pcre2_jit_stack_create_32 #( size_t anInitialSize
		      #, size_t aMaximumSize #, nil ) )
]

{ #category : 'library path' }
PCRE2UTF32JITStack >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'external resource management' }
PCRE2UTF32JITStack >> free [
	"Free this libpcre2-32 JIT stack. The caller must ensure no active or future match context still points to it."

	self ffiCall: #( void pcre2_jit_stack_free_32 #( self ) )
]
