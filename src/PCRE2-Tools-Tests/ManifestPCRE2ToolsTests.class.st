"
I hold the package-level lint configuration for PCRE2-Tools-Tests, so the tool tests are checked under the same rules as the rest of the project.
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
