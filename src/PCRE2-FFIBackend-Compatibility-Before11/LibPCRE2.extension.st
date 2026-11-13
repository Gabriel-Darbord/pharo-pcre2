Extension { #name : 'LibPCRE2' }

{ #category : '*PCRE2-FFIBackend-Compatibility-Before11' }
LibPCRE2 >> calloutAPIClass [
	"Register callbacks as Pharo 11 does: see PCRE2CalloutAPI."

	^ PCRE2CalloutAPI
]
