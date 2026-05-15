"
JIT stack wrapper for PCRE2's 8-bit UTF-8 API.

Instances are explicit advanced resources. Assign one to a PCRE2UTF8MatchContext when a JIT-compiled pattern needs more runtime stack than PCRE2's default.
"
Class {
	#name : 'PCRE2UTF8JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'memory management' }
PCRE2UTF8JITStack class >> freeUnusedMemory [

	^ LibPCRE2 jitFreeUnusedMemory
]

{ #category : 'private' }
PCRE2UTF8JITStack >> codeUnitWidth [

	^ 8
]

{ #category : 'private' }
PCRE2UTF8JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [
	"Create a JIT stack for libpcre2-8."

	self ffiCall:
		#( void #* pcre2_jit_stack_create_8 #( size_t anInitialSize
		      #, size_t aMaximumSize #, nil ) )
]

{ #category : 'library path' }
PCRE2UTF8JITStack >> ffiLibraryName [

	^ LibPCRE2
]

{ #category : 'external resource management' }
PCRE2UTF8JITStack >> free [
	"Free this libpcre2-8 JIT stack. The caller must ensure no active or future match context still points to it."

	self ffiCall: #( void pcre2_jit_stack_free_8 #( self ) )
]
