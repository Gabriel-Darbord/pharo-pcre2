"
I hold the package-level lint configuration for PCRE2-Tools, so the debugger and trace tools are checked under the same rules as the rest of the project.
"
Class {
	#name : 'ManifestPCRE2Tools',
	#superclass : 'PackageManifest',
	#category : 'PCRE2-Tools-Manifest',
	#package : 'PCRE2-Tools',
	#tag : 'Manifest'
}

{ #category : 'formatting' }
ManifestPCRE2Tools class >> formatter [

	^ ManifestBaselineOfPCRE2 formatter
]
