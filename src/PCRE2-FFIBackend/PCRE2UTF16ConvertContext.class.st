"
Convert context of the 16-bit PCRE2 library.
"
Class {
	#name : 'PCRE2UTF16ConvertContext',
	#superclass : 'PCRE2ConvertContext',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'external resource management' }
PCRE2UTF16ConvertContext >> basicFree [

	self ffiCall: #(void pcre2_convert_context_free_16(self))
]

{ #category : 'library path' }
PCRE2UTF16ConvertContext >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_convert_context_copy_16(self))
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> setGlobEscape: codePoint [

	self ffiCall: #(int pcre2_set_glob_escape_16(self, uint32 codePoint))
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> setGlobSeparator: codePoint [

	self ffiCall: #(int pcre2_set_glob_separator_16(self, uint32 codePoint))
]
