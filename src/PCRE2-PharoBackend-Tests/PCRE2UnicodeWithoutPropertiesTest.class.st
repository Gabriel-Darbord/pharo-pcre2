"
The Pharo backend as the minimal core installs it, without `PCRE2-UnicodeProperties`: general categories, caseless matching and the classes built on them still work, and every feature that needs the missing properties says so when the pattern is compiled.

Each test unregisters the properties for its own run and registers them back.
"
Class {
	#name : 'PCRE2UnicodeWithoutPropertiesTest',
	#superclass : 'TestCase',
	#instVars : [
		'properties'
	],
	#category : 'PCRE2-PharoBackend-Tests',
	#package : 'PCRE2-PharoBackend-Tests'
}

{ #category : 'private' }
PCRE2UnicodeWithoutPropertiesTest >> compile: pattern [

	^ PCRE2Compiler new
		  backend: PCRE2CompilerPharoBackend;
		  compile: pattern
]

{ #category : 'running' }
PCRE2UnicodeWithoutPropertiesTest >> setUp [

	super setUp.
	properties := PCRE2UnicodeData properties.
	PCRE2UnicodeData properties: nil
]

{ #category : 'running' }
PCRE2UnicodeWithoutPropertiesTest >> tearDown [

	PCRE2UnicodeData properties: properties.
	super tearDown
]

{ #category : 'tests' }
PCRE2UnicodeWithoutPropertiesTest >> testCaselessMatchingNeedsNoProperties [

	self assert: ((self compile: '(?i)k') matches: (Character value: 16r212A) asString).
	self assert: ((self compile: '(?i)[A-Z]') matches: 'ſ').
	self assert: ((self compile: '(?i)(k)\1') matches: 'kK').
	self assert: ((self compile: '(?i)\p{Lu}') matches: 'a')
]

{ #category : 'tests' }
PCRE2UnicodeWithoutPropertiesTest >> testGeneralCategoriesNeedNoProperties [

	self assert: ((self compile: '\p{Lu}+') find: 'abCDé') equals: 'CD'.
	self assert: ((self compile: '\p{L&}') matches: 'é').
	self deny: ((self compile: '\P{L}') matches: 'é').
	self assert: ((self compile: '\p{Nd}') matches: (Character value: 16r0663) asString).
	self assert: ((self compile: '(*UCP)\w+') find: '-été-') equals: 'été'.
	self assert: ((self compile: '(*UCP)[[:alpha:]]') matches: 'é').
	self assert: ((self compile: '\p{Xan}+') find: '-a1-') equals: 'a1'.
	self assert: ((self compile: '(?<é>a)\k<é>') matches: 'aa')
]

{ #category : 'tests' }
PCRE2UnicodeWithoutPropertiesTest >> testPropertiesPharoHasNoTableForNeedThePackage [

	#( '\p{Greek}' '\p{sc=Grek}' '\P{Emoji}' '\p{bc=AL}' '\X' '(*sr:a)' '(*atomic_script_run:a)' '\p{Foo}' ) do: [ :pattern |
		self should: [ self compile: pattern ] raise: PCRE2UnsupportedFeature ]
]
