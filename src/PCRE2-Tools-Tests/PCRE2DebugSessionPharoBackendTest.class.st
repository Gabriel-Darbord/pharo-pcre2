"
I run the PCRE2-Tools debugger tests on the Pharo backend, the one a plain install gets.
"
Class {
	#name : 'PCRE2DebugSessionPharoBackendTest',
	#superclass : 'PCRE2DebugSessionTest',
	#category : 'PCRE2-Tools-Tests-Debugging',
	#package : 'PCRE2-Tools-Tests',
	#tag : 'Debugging'
}

{ #category : 'testing' }
PCRE2DebugSessionPharoBackendTest class >> backendClass [

	^ PCRE2CompilerPharoBackend
]
