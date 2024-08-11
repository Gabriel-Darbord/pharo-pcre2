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
		spec package: #PCRE2.
		spec package: #'PCRE2-Tests' with: [ spec requires: #( 'PCRE2' ) ].

		spec group: 'core' with: #( 'PCRE2' ).
		spec group: 'tests' with: #( 'PCRE2-Tests' ).
		spec group: 'default' with: #( 'core' 'tests' ) ]
]
