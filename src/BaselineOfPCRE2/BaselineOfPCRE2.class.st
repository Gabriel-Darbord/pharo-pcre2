"
Metacello baseline of the PCRE2 binding: its packages, the groups that load each backend and feature, and their tests.
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
			spec package: 'PCRE2-Trace' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-Substitution' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-DFA' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-Wide' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-FFIBackend' with: [ spec requires: #( 'PCRE2' 'PCRE2-Substitution' 'PCRE2-Wide' ) ].
			spec package: 'PCRE2-PharoBackend' with: [ spec requires: #( 'PCRE2' ) ].
			spec package: 'PCRE2-PharoBackend-Substitution' with: [ spec requires: #( 'PCRE2-PharoBackend' 'PCRE2-Substitution' ) ].
			spec package: 'PCRE2-PharoBackend-DFA' with: [ spec requires: #( 'PCRE2-PharoBackend' 'PCRE2-DFA' ) ].
			spec package: 'PCRE2-UnicodeProperties' with: [ spec requires: #( 'PCRE2-PharoBackend' ) ].
			spec package: 'PCRE2-Tools' with: [ spec requires: #( 'PCRE2-Trace' ) ].
			spec package: 'PCRE2-Tests' with: [ spec requires: #( 'PCRE2-FFIBackend' 'PCRE2-Trace' 'PCRE2-DFA' 'PCRE2-Wide' ) ].
			spec package: 'PCRE2-PharoBackend-Tests' with: [
					spec requires: #( 'PCRE2-PharoBackend' 'PCRE2-UnicodeProperties' 'PCRE2-PharoBackend-Substitution'
						   'PCRE2-PharoBackend-DFA' 'PCRE2-Wide' ) ].
			"The tools run on either backend, so their tests only need the one a plain install gets."
			spec package: 'PCRE2-Tools-Tests' with: [ spec requires: #( 'PCRE2-Tools' 'PCRE2-PharoBackend' 'PCRE2-Wide' ) ].
			"PCRE2DebugSessionFFIBackendTest runs the cases of the tools tests on the C library, so it needs their package."
			spec package: 'PCRE2-BackendIntegration-Tests' with: [
					spec requires:
						#( 'PCRE2-FFIBackend' 'PCRE2-PharoBackend' 'PCRE2-PharoBackend-Substitution' 'PCRE2-PharoBackend-DFA'
						   'PCRE2-Tools-Tests' 'PCRE2-Wide' ) ].
			spec group: 'Core' with: #( 'PCRE2' ).
			"Each feature group brings the shared API of the feature, and its Pharo implementation where one exists."
			spec group: 'Trace' with: #( 'PCRE2-Trace' ).
			spec group: 'Wide' with: #( 'PCRE2-Wide' ).
			spec group: 'Substitution' with: #( 'PCRE2-PharoBackend-Substitution' ).
			spec group: 'DFA' with: #( 'PCRE2-PharoBackend-DFA' ).
			"Scripts, bidi classes, binary properties, \X and script runs, which Pharo has no Unicode table for."
			spec group: 'UnicodeProperties' with: #( 'PCRE2-UnicodeProperties' ).
			"The C binding implements every feature, so it comes with the shared API of all of them."
			spec group: 'FFI' with: #( 'PCRE2-FFIBackend' 'PCRE2-Trace' 'PCRE2-Substitution' 'PCRE2-DFA' 'PCRE2-Wide' ).
			"The Pharo backend matching UTF-8 subjects on the image's own Unicode tables, with none of the feature groups."
			spec group: 'PharoMinimal' with: #( 'PCRE2-PharoBackend' ).
			spec group: 'Pharo' with: #( 'PharoMinimal' 'Trace' 'Wide' 'Substitution' 'DFA' 'UnicodeProperties' ).
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
		for: #( #'pharo10.x' #'pharo11.x' #'pharo12.x' #'pharo13.x' #'pharo14.x' )
		do: [ "These images carry Unicode 9.0 tables, so the Pharo backend brings its own general categories, case folding and digits."
				spec package: 'PCRE2-UnicodeCompat' with: [ spec requires: #( 'PCRE2-UnicodeProperties' ) ].
				spec package: 'PCRE2-PharoBackend' with: [ spec includes: #( 'PCRE2-UnicodeCompat' ) ] ].
	spec for: #( #'pharo10.x' #'pharo11.x' ) do: [ "What the tools use of Pharo 12 and later, for the versions before it."
			spec package: 'PCRE2-Compatibility-Before12'.
			spec package: 'PCRE2-Tools' with: [ spec requires: #( 'PCRE2-Compatibility-Before12' ) ] ].
	spec for: #'pharo10.x' do: [ "What the tools use of Pharo 11 and later, for Pharo 10."
			spec package: 'PCRE2-Compatibility-Before11'.
			spec package: 'PCRE2-Tools' with: [ spec requires: #( 'PCRE2-Compatibility-Before11' ) ] ]
]
