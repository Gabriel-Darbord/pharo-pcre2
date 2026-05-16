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
		spec
			baseline: 'PharoCompatibility'
			with: [
				spec
					repository:
						'github://Evref-BL/PharoCompatibility:main/src';
					loads: #( 'Pharo13Surface' ) ].

		spec package: #PCRE2 with: [
			spec requires: #( 'PharoCompatibility' ) ].
		spec package: #'PCRE2-Tools' with: [ spec requires: #( 'PCRE2' ) ].
		spec package: #'PCRE2-Tests' with: [ spec requires: #( 'PCRE2' ) ].
		spec
			package: #'PCRE2-Tools-Tests'
			with: [ spec requires: #( 'PCRE2-Tools' ) ].

		spec group: 'core' with: #( 'PCRE2' ).
		spec group: 'tools' with: #( 'PCRE2-Tools' ).
		spec group: 'tests' with: #( 'PCRE2-Tests' 'PCRE2-Tools-Tests' ).
		spec group: 'default' with: #( 'core' 'tools' 'tests' ) ]
]
