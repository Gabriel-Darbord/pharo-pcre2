"
Convert context of the 8-bit PCRE2 library.
"
Class {
	#name : 'PCRE2UTF8ConvertContext',
	#superclass : 'PCRE2ConvertContext',
	#category : 'PCRE2-FFIBackend',
	#package : 'PCRE2-FFIBackend'
}

{ #category : 'external resource management' }
PCRE2UTF8ConvertContext >> basicFree [

	self ffiCall: #(void pcre2_convert_context_free_8(self))
]

{ #category : 'library path' }
PCRE2UTF8ConvertContext >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> privateCopy [
	"Answer NULL when memory cannot be obtained."

	self ffiCall: #(void *pcre2_convert_context_copy_8(self))
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> setGlobEscape: codePoint [

	self ffiCall: #(int pcre2_set_glob_escape_8(self, uint32 codePoint))
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> setGlobSeparator: codePoint [

	self ffiCall: #(int pcre2_set_glob_separator_8(self, uint32 codePoint))
]
