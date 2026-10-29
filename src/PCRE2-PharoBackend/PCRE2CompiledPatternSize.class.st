"
Measures the storage owned by a Pharo compiled pattern, excluding shared executable methods and Unicode tables. Reflection is confined to this diagnostic traversal.
"
Class {
	#name : 'PCRE2CompiledPatternSize',
	#superclass : 'Object',
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'diagnostics' }
PCRE2CompiledPatternSize class >> of: object seen: seen [

	| size |
	(object isNil or: [
		 object isInteger or: [ object isSymbol or: [ object isCharacter or: [ object == true or: [ object == false ] ] ] ] ]) ifTrue: [
		^ 0 ].
	(seen includes: object) ifTrue: [ ^ 0 ].
	seen add: object.
	size := object sizeInMemory.
	(object isKindOf: PCRE2PatternNode) ifTrue: [
			1 to: object class instSize do: [ :index | size := size + (self of: (object instVarAt: index) seen: seen) ].
			^ size ].
	object isDictionary ifTrue: [
			object keysAndValuesDo: [ :key :value | size := size + (self of: key seen: seen) + (self of: value seen: seen) ].
			^ size ].
	(object isArray or: [ object isKindOf: OrderedCollection ]) ifTrue: [
			object do: [ :value | size := size + (self of: value seen: seen) ].
			^ size ].
	(object isKindOf: PCRE2CalloutSite) ifTrue: [ size := size + (self of: object string seen: seen) ].
	^ size
]
