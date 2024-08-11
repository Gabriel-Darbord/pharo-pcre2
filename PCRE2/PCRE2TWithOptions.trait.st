Trait {
	#name : 'PCRE2TWithOptions',
	#instVars : [
		'options'
	],
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'accessing' }
PCRE2TWithOptions >> addOptions: anInteger [

	options := options bitOr: anInteger
]

{ #category : 'accessing' }
PCRE2TWithOptions >> options [
	"Use `PCRE2 readOptions:(for:)` to find out which flags are active (for a function)"

	^ options
]

{ #category : 'accessing' }
PCRE2TWithOptions >> options: anInteger [
	"See class-side of PCRE2 and the options protocol for valid arguments"

	options := anInteger
]

{ #category : 'accessing' }
PCRE2TWithOptions >> removeOptions: anInteger [

	options := options bitAnd: anInteger bitInvert
]
