"
Tests that need both backends: behavior the two must agree on, run once per backend and code-unit width; the two living side by side in one image; and the tools on the FFI backend.
"
Class {
	#name : 'ManifestPCRE2BackendIntegrationTests',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-BackendIntegration-Tests-Manifest',
	#package : 'PCRE2-BackendIntegration-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2BackendIntegrationTests class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
