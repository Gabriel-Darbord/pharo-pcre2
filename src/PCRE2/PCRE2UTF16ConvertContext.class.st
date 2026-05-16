"
Convert context for PCRE2's 16-bit code-unit API.

The common convert-context accessors live on PCRE2ConvertContext. This subclass binds native setters, copier, and finalizer to libpcre2-16.
"
Class {
	#name : 'PCRE2UTF16ConvertContext',
	#superclass : 'PCRE2ConvertContext',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF16ConvertContext >> ffiLibraryName [

	^ LibPCRE2UTF16
]

{ #category : 'external resource management' }
PCRE2UTF16ConvertContext >> free [
	"Free the native UTF-16 convert context. PCRE2 ignores NULL."

	self ffiCall: #( void pcre2_convert_context_free_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> privateCopy [
	"Create a native copy of this UTF-16 convert context.
	pcre2_convert_context *pcre2_convert_context_copy_16(pcre2_convert_context *cvcontext)"

	self ffiCall: #( void #* pcre2_convert_context_copy_16
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> setGlobEscape: codePoint [
	"Set the native glob escape character.
	int pcre2_set_glob_escape_16(pcre2_convert_context *cvcontext, uint32_t escape_char)"

	self ffiCall:
		#( int pcre2_set_glob_escape_16 #( self #, uint32 codePoint ) )
]

{ #category : 'private' }
PCRE2UTF16ConvertContext >> setGlobSeparator: codePoint [
	"Set the native glob path separator.
	int pcre2_set_glob_separator_16(pcre2_convert_context *cvcontext, uint32_t separator_char)"

	self ffiCall:
		#( int pcre2_set_glob_separator_16 #( self #, uint32 codePoint ) )
]
