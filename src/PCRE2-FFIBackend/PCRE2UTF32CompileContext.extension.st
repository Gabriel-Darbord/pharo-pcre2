Extension { #name : 'PCRE2UTF32CompileContext' }

{ #category : '*PCRE2-FFIBackend' }
PCRE2UTF32CompileContext class >> fromHandle: address [

	^ self new backend: (PCRE2CompileContextUTF32FFIBackend fromHandle: address) initialize autoRelease
]
