"
Metacello baseline for the PCRE2 binding.

It loads the core PCRE2 package and its tests so the binding can be installed or validated as one project.
"
Class {
	#name : 'BaselineOfPCRE2',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPCRE2',
	#package : 'BaselineOfPCRE2'
}

{ #category : 'baselines' }
BaselineOfPCRE2 >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec package: 'PCRE2'.
			spec package: 'PCRE2-FFIBackend' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-PharoBackend' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-UnicodeProperties' with: [ spec requires: #( 'PCRE2-PharoBackend' ) ].
			spec package: 'PCRE2-Tools' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-Tests' with: [ spec requires: #( 'PCRE2-FFIBackend' ) ].
			spec package: 'PCRE2-PharoBackend-Tests' with: [ spec requires: #( 'PCRE2-PharoBackend' 'PCRE2-UnicodeProperties' ) ].
			"The tools run on either backend, so their tests only need the one a plain install gets."
			spec package: 'PCRE2-Tools-Tests' with: [ spec requires: #( 'PCRE2-Tools' 'PCRE2-PharoBackend' ) ].
			spec
				package: 'PCRE2-BackendIntegration-Tests'
				with: [ spec requires: #( 'PCRE2-FFIBackend' 'PCRE2-PharoBackend' 'PCRE2-Tools' ) ].
			spec group: 'Core' with: #( 'PCRE2' ).
			spec group: 'FFI' with: #( 'PCRE2-FFIBackend' ).
			"Scripts, bidi classes, binary properties, \X and script runs, which Pharo has no Unicode table for."
			spec group: 'UnicodeProperties' with: #( 'PCRE2-UnicodeProperties' ).
			spec group: 'Pharo' with: #( 'PCRE2-PharoBackend' 'UnicodeProperties' ).
			"The Pharo backend on the image's own Unicode tables, without UnicodeProperties."
			spec group: 'PharoMinimal' with: #( 'PCRE2-PharoBackend' ).
			spec group: 'Backends' with: #( 'FFI' 'Pharo' ).
			spec group: 'Tools' with: #( 'PCRE2-Tools' ).
			spec group: 'FFITests' with: #( 'PCRE2-Tests' ).
			spec group: 'PharoTests' with: #( 'PCRE2-PharoBackend-Tests' ).
			spec group: 'ToolsTests' with: #( 'PCRE2-Tools-Tests' ).
			spec group: 'BackendTests' with: #( 'PCRE2-BackendIntegration-Tests' ).
			spec group: 'Tests' with: #( 'FFITests' 'PharoTests' 'ToolsTests' 'BackendTests' ).
			"Metacello loads the group named 'default' when none is given."
			spec group: 'default' with: #( 'Core' 'Pharo' ).
			spec group: 'All' with: #( 'Backends' 'Tools' 'Tests' ) ].
	spec
		for: #( #'pharo12.x' #'pharo13.x' #'pharo14.x' )
		do: [ "These images carry Unicode 9.0 tables, so the Pharo backend brings its own general categories, case folding and digits.
			They are packed the way the properties are, and read with the same decoder."
				spec package: 'PCRE2-UnicodeCompat' with: [ spec requires: #( 'PCRE2-UnicodeProperties' ) ].
				spec package: 'PCRE2-PharoBackend' with: [ spec includes: #( 'PCRE2-UnicodeCompat' ) ] ]
]
