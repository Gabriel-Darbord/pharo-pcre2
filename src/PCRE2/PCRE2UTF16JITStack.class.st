"
JIT stack wrapper for PCRE2's 16-bit code-unit API.

Instances are explicit advanced resources. Assign one to a PCRE2UTF16MatchContext when a JIT-compiled pattern needs more runtime stack than PCRE2's default.
"
Class {
	#name : 'PCRE2UTF16JITStack',
	#superclass : 'PCRE2JITStack',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'memory management' }
PCRE2UTF16JITStack class >> freeUnusedMemory [

	^ LibPCRE2UTF16 jitFreeUnusedMemory
]

{ #category : 'private' }
PCRE2UTF16JITStack >> codeUnitWidth [

	^ 16
]

{ #category : 'private' }
PCRE2UTF16JITStack >> createWithStartSize: anInitialSize maxSize: aMaximumSize [
	"Create a JIT stack for libpcre2-16."

	self ffiCall:
		#( void #* pcre2_jit_stack_create_16 #( size_t anInitialSize
		      #, size_t aMaximumSize #, nil ) )
]

{ #category : 'library path' }
PCRE2UTF16JITStack >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'external resource management' }
PCRE2UTF16JITStack >> free [
	"Free this libpcre2-16 JIT stack. The caller must ensure no active or future match context still points to it."

	self ffiCall: #( void pcre2_jit_stack_free_16 #( self ) )
]
