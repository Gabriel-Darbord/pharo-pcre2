"
I run the PCRE2-Tools debugger tests on the FFI backend, so the tools are known to behave the same on the C library as on the Pharo engine. I live with the other cross-backend tests because I need both the tools and the FFI backend loaded.
"
Class {
	#name : 'PCRE2DebugSessionFFIBackendTest',
	#superclass : 'PCRE2DebugSessionTest',
	#category : 'PCRE2-BackendIntegration-Tests-Debugging',
	#package : 'PCRE2-BackendIntegration-Tests',
	#tag : 'Debugging'
}

{ #category : 'testing' }
PCRE2DebugSessionFFIBackendTest class >> backendClass [

	^ PCRE2CompilerFFIBackend
]
