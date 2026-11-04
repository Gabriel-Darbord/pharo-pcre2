"
Tests of the debugger and trace tools on the Pharo backend. PCRE2-BackendIntegration-Tests runs them on the FFI backend.
"
Class {
	#name : 'ManifestPCRE2ToolsTests',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Tools-Tests-Manifest',
	#package : 'PCRE2-Tools-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2ToolsTests class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
