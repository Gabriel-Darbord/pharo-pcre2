"
Convert context of the 32-bit PCRE2 library.
"
Class {
	#name : 'PCRE2UTF32ConvertContext',
	#superclass : 'PCRE2ConvertContext',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'external resource management' }
PCRE2UTF32ConvertContext >> basicFree [

	self ffiCall: #(void pcre2_convert_context_free_32(self))
]

{ #category : 'library path' }
PCRE2UTF32ConvertContext >> ffiLibraryName [

	^ LibPCRE2UTF32
]

{ #category : 'private' }
PCRE2UTF32ConvertContext >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_convert_context_copy_32(self))
]

{ #category : 'private' }
PCRE2UTF32ConvertContext >> setGlobEscape: codePoint [

	self ffiCall: #(int pcre2_set_glob_escape_32(self, uint32 codePoint))
]

{ #category : 'private' }
PCRE2UTF32ConvertContext >> setGlobSeparator: codePoint [

	self ffiCall: #(int pcre2_set_glob_separator_32(self, uint32 codePoint))
]
