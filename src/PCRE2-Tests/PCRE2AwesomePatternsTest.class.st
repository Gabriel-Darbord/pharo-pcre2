"
I cover expressive PCRE2 pattern features that are useful examples but are not specific to one PCRE2Matcher API method.
"
Class {
	#name : 'PCRE2AwesomePatternsTest',
	#superclass : 'TestCase',
	#category : 'PCRE2-Tests',
	#package : 'PCRE2-Tests'
}

{ #category : 'tests' }
PCRE2AwesomePatternsTest >> testIndexedCaptureBackreferenceFindsRepeatingWords [

	| regex |
	regex := '\b(\w+)\b\s+\1\b' asPerlCompatibleRegex.
	self
		assert:
		(regex findAll: 'the the thing is  is here to to help') asArray
		equals: { 'the the'. 'is  is'. 'to to' }
]

{ #category : 'tests' }
PCRE2AwesomePatternsTest >> testNamedCaptureBackreferenceMatchesSameClosingTag [

	| regex |
	regex := '<(?<tag>\w+)>(?<contents>.*?)<\/\k<tag>>' asPerlCompatibleRegex.
	self
		assert: (regex find: 'XML: <foo>hello</bar></foo>')
		equals: '<foo>hello</bar></foo>'
]

{ #category : 'tests' }
PCRE2AwesomePatternsTest >> testRecursivePatternFindsNestedBraceGroups [

	| regex |
	regex := '{((?>[^{}]+|(?R))*)}' asPerlCompatibleRegex.
	self
		assert: (regex findAll: '{1, {2, {3}}} {{4, 5}}') asArray
		equals: { '{1, {2, {3}}}'. '{{4, 5}}' }
]
