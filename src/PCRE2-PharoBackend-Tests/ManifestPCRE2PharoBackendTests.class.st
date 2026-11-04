"
Tests of the Pharo backend, with every feature package loaded, and of what it still does once PCRE2-UnicodeProperties is unregistered.
"
Class {
	#name : 'ManifestPCRE2PharoBackendTests',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-PharoBackend-Tests-Manifest',
	#package : 'PCRE2-PharoBackend-Tests',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2PharoBackendTests class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
