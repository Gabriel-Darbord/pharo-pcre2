"
Convert context for PCRE2's 8-bit UTF-8 API.

The common convert-context accessors live on PCRE2ConvertContext. This subclass binds native setters, copier, and finalizer to libpcre2-8.
"
Class {
	#name : 'PCRE2UTF8ConvertContext',
	#superclass : 'PCRE2ConvertContext',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'library path' }
PCRE2UTF8ConvertContext >> ffiLibraryName [

	^ LibPCRE2UTF8
]

{ #category : 'external resource management' }
PCRE2UTF8ConvertContext >> free [
	"Free the native convert context. PCRE2 ignores NULL."

	self ffiCall: #( void pcre2_convert_context_free_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> privateCopy [
	"Create a native copy of this UTF-8 convert context.
	pcre2_convert_context *pcre2_convert_context_copy_8(pcre2_convert_context *cvcontext)"

	self ffiCall: #( void #* pcre2_convert_context_copy_8
	   #( self ) )
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> setGlobEscape: codePoint [
	"Set the native glob escape character.
	int pcre2_set_glob_escape_8(pcre2_convert_context *cvcontext, uint32_t escape_char)"

	self ffiCall:
		#( int pcre2_set_glob_escape_8 #( self #, uint32 codePoint ) )
]

{ #category : 'private' }
PCRE2UTF8ConvertContext >> setGlobSeparator: codePoint [
	"Set the native glob path separator.
	int pcre2_set_glob_separator_8(pcre2_convert_context *cvcontext, uint32_t separator_char)"

	self ffiCall:
		#( int pcre2_set_glob_separator_8 #( self #, uint32 codePoint ) )
]
