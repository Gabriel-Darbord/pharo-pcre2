"
The Unicode questions the Pharo backend asks while it compiles and matches: general categories and the classes built on them (`\w`, `\s`, `\d`, POSIX classes, `\p{L}`), caseless comparison, and the properties and grapheme clusters of `PCRE2-UnicodeProperties`.

Two registered objects answer them:

- `tables` answers general categories, case folding and decimal digits. It is `PCRE2PharoUnicodeTables`, reading the image's own `Unicode` class, unless `PCRE2-UnicodeCompat` registers `PCRE2PackedUnicodeTables` for an image whose tables are too old.
- `properties` answers scripts, script extensions, bidi classes, binary properties, grapheme breaks and script runs. It is `PCRE2UnicodeProperties` once `PCRE2-UnicodeProperties` is loaded; without it, a pattern using them fails to compile with `PCRE2UnsupportedFeature`.
"
Class {
	#name : 'PCRE2UnicodeData',
	#superclass : 'Object',
	#classVars : [
		'Properties',
		'Tables'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'properties' }
PCRE2UnicodeData class >> case: character upper: upper unicode: unicode [

	| code category |
	code := character asInteger.
	unicode ifFalse: [
			^ code < 128
				  ifTrue: [
						  upper
							  ifTrue: [ character asUppercase ]
							  ifFalse: [ character asLowercase ] ]
				  ifFalse: [ character ] ].
	category := upper
		            ifTrue: [ #lu ]
		            ifFalse: [ #ll ].
	(self category: category includes: code) ifTrue: [ ^ character ].
	^ Character value: ((self equivalents: code) detect: [ :other | self category: category includes: other ] ifNone: [ code ])
]

{ #category : 'properties' }
PCRE2UnicodeData class >> category: category includes: code [
	"Answer whether code is in category: a general category such as #lu, a major class such as #l, or #lc for the cased letters."

	| actual |
	actual := self generalCategoryOf: code.
	category size = 1 ifTrue: [ ^ actual first = category first ].
	category == #lc ifTrue: [ ^ #( #lu #ll #lt ) includes: actual ].
	^ actual == category
]

{ #category : 'properties' }
PCRE2UnicodeData class >> categoryNames [
	"The categories a pattern can name in \p{...}: every general category, every major class, and lc for the cased letters."

	^ #( #c #cc #cf #cn #co #cs #l #lc #ll #lm #lo #lt #lu #m #mc #me #mn #n #nd #nl #no #p #pc #pd #pe #pf #pi #po #ps #s #sc #sk
	     #sm #so #z #zl #zp #zs )
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> decimalValueOf: code [
	"Answer the value of code as a decimal digit, or nil when it is none."

	^ self tables decimalValueOf: code
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> equivalents: code [

	^ self tables equivalents: code
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> equivalentsUnder: folding [
	"Answer every code that folding maps, or maps another code to, with all the codes sharing its folding in ascending order."

	| classes equivalents |
	classes := Dictionary new.
	folding keysAndValuesDo: [ :code :folded | (classes at: folded ifAbsentPut: [ Set with: folded ]) add: code ].
	equivalents := Dictionary new.
	classes do: [ :each |
			| codes |
			codes := each asArray sort.
			codes do: [ :code | equivalents at: code put: codes ] ].
	^ equivalents
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> fold: code [

	^ self tables fold: code
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> generalCategoryOf: code [
	"Answer the short name of the general category of code, such as #lu, unassigned beyond Unicode."

	code > 16r10FFFF ifTrue: [ ^ #cn ].
	^ self tables generalCategoryOf: code
]

{ #category : 'graphemes' }
PCRE2UnicodeData class >> graphemeEndIn: subject from: position [

	^ (self requireProperties: '\X') graphemeEndIn: subject from: position
]

{ #category : 'registration' }
PCRE2UnicodeData class >> hasProperties [

	^ Properties isNotNil
]

{ #category : 'properties' }
PCRE2UnicodeData class >> inRange: code from: low to: high unicode: unicode [

	(code between: low and: high) ifTrue: [ ^ true ].
	unicode ifTrue: [ ^ (self equivalents: code) anySatisfy: [ :other | other between: low and: high ] ].
	(code between: 65 and: 90) ifTrue: [ ^ code + 32 between: low and: high ].
	(code between: 97 and: 122) ifTrue: [ ^ code - 32 between: low and: high ].
	^ false
]

{ #category : 'properties' }
PCRE2UnicodeData class >> inRange: code from: low to: high unicode: unicode extraOptions: flags [

	| restricted variants |
	restricted := (flags bitAnd: PCRE2 extraCaselessRestrict) ~= 0.
	(unicode and: [ restricted not and: [ (flags bitAnd: PCRE2 extraTurkishCasing) ~= 0 ] ]) ifTrue: [
			variants := self turkishEquivalents: code.
			variants ifNotNil: [ ^ variants anySatisfy: [ :other | other between: low and: high ] ] ].
	^ self
		  inRange: code
		  from: low
		  to: high
		  unicode: unicode
		  restricted: restricted
]

{ #category : 'properties' }
PCRE2UnicodeData class >> inRange: code from: low to: high unicode: unicode restricted: restricted [

	(restricted and: [ unicode ]) ifFalse: [
			^ self
				  inRange: code
				  from: low
				  to: high
				  unicode: unicode ].
	^ (self equivalents: code) anySatisfy: [ :other | code < 128 = (other < 128) and: [ other between: low and: high ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> isGraph: code [

	| category |
	category := self generalCategoryOf: code.
	category first = $z ifTrue: [ ^ false ].
	category first = $c ifFalse: [ ^ true ].
	^ category == #cf and: [ code ~= 16r061C and: [ code ~= 16r180E and: [ (code between: 16r2066 and: 16r2069) not ] ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> isPrint: code [

	| category |
	category := self generalCategoryOf: code.
	(category == #zl or: [ category == #zp ]) ifTrue: [ ^ false ].
	category first = $c ifFalse: [ ^ true ].
	^ category == #cf and: [ code ~= 16r061C and: [ (code between: 16r2066 and: 16r2069) not ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> isScriptRun: text from: start to: end [

	^ (self requireProperties: 'A script run') isScriptRun: text from: start to: end
]

{ #category : 'properties' }
PCRE2UnicodeData class >> isSpace: code [

	^ (code between: 9 and: 13) or: [ code = 133 or: [ (self generalCategoryOf: code) first = $z ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> isWord: code [

	| category |
	category := self generalCategoryOf: code.
	^ category first = $l or: [ category first = $n or: [ category == #mn or: [ category == #pc ] ] ]
]

{ #category : 'accessing' }
PCRE2UnicodeData class >> normalize: text [

	^ (text reject: [ :character | character isSeparator or: [ '_-' includes: character ] ]) asLowercase
]

{ #category : 'properties' }
PCRE2UnicodeData class >> posixPredicate: property unicode: unicode caseless: caseless [

	| normalized |
	normalized := self normalize: property.
	(normalized beginsWith: '^') ifTrue: [
		^ [ :character | ((self posixPredicate: normalized allButFirst unicode: unicode caseless: caseless) value: character) not ] ].
	unicode ifTrue: [ ^ self unicodePosixPredicate: normalized caseless: caseless ].
	normalized = 'ascii' ifTrue: [ ^ [ :character | character asInteger < 128 ] ].
	normalized = 'graph' ifTrue: [ ^ [ :character | character asInteger between: 33 and: 126 ] ].
	normalized = 'print' ifTrue: [ ^ [ :character | character asInteger between: 32 and: 126 ] ].
	normalized = 'blank' ifTrue: [ ^ [ :character | #( 9 32 ) includes: character asInteger ] ].
	normalized = 'cntrl' ifTrue: [ ^ [ :character | character asInteger < 32 or: [ character asInteger = 127 ] ] ].
	normalized = 'space' ifTrue: [ ^ [ :character | #( 9 10 11 12 13 32 ) includes: character asInteger ] ].
	normalized = 'digit' ifTrue: [ ^ [ :character | character between: $0 and: $9 ] ].
	normalized = 'xdigit' ifTrue: [
		^ [ :character | (character between: $0 and: $9) or: [ (character between: $a and: $f) or: [ character between: $A and: $F ] ] ] ].
	^ [ :character | character asInteger < 128 and: [ (self unicodePosixPredicate: normalized caseless: caseless) value: character ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> predicateFor: property caseless: caseless [

	| normalized predicate category |
	normalized := self normalize: property.
	(normalized beginsWith: '^') ifTrue: [
			predicate := self predicateFor: normalized allButFirst caseless: caseless.
			^ [ :character | (predicate value: character) not ] ].
	normalized = 'any' ifTrue: [ ^ [ :character | true ] ].
	normalized = 'ascii' ifTrue: [ ^ [ :character | character asInteger < 128 ] ].
	normalized = 'xuc' ifTrue: [
			^ [ :character |
				  character asInteger < 160
					  ifTrue: [ #( 36 64 96 ) includes: character asInteger ]
					  ifFalse: [ (character asInteger between: 16rD800 and: 16rDFFF) not ] ] ].
	normalized = 'xan' ifTrue: [
		^ [ :character | (self category: #l includes: character asInteger) or: [ self category: #n includes: character asInteger ] ] ].
	normalized = 'xwd' ifTrue: [ ^ [ :character | self isWord: character asInteger ] ].
	(#( 'xps' 'xsp' ) includes: normalized) ifTrue: [ ^ [ :character | self isSpace: character asInteger ] ].
	category := (normalized = 'l&'
		             ifTrue: [ 'lc' ]
		             ifFalse: [ normalized ]) asSymbol.
	(self categoryNames includes: category) ifFalse: [
		^ (self requireProperties: 'The Unicode property ' , property) predicateFor: property ].
	(caseless and: [ #( #lu #ll #lt ) includes: category ]) ifTrue: [ category := #lc ].
	^ [ :character | self category: category includes: character asInteger ]
]

{ #category : 'registration' }
PCRE2UnicodeData class >> properties [
	"Answer the registered properties Pharo has no table for, or nil when none are."

	^ Properties
]

{ #category : 'registration' }
PCRE2UnicodeData class >> properties: unicodeProperties [
	"Answer the properties Pharo has no table for from unicodeProperties, or from nobody when it is nil."

	Properties := unicodeProperties
]

{ #category : 'registration' }
PCRE2UnicodeData class >> requireProperties: feature [
	"Answer the registered properties, or signal that feature needs them when none are."

	^ Properties ifNil: [ PCRE2UnsupportedFeature signal: feature , ' needs the PCRE2-UnicodeProperties package' ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> same: first as: second unicode: unicode [

	unicode ifTrue: [ ^ (self fold: first asInteger) = (self fold: second asInteger) ].
	^ first = second or: [ (first asInteger < 128 and: [ second asInteger < 128 ]) and: [ first asLowercase = second asLowercase ] ]
]

{ #category : 'properties' }
PCRE2UnicodeData class >> same: first as: second unicode: unicode extraOptions: flags [

	| restricted variants |
	restricted := (flags bitAnd: PCRE2 extraCaselessRestrict) ~= 0.
	(unicode and: [ restricted not and: [ (flags bitAnd: PCRE2 extraTurkishCasing) ~= 0 ] ]) ifTrue: [
			variants := self turkishEquivalents: first asInteger.
			variants ifNotNil: [ ^ variants includes: second asInteger ] ].
	^ self
		  same: first
		  as: second
		  unicode: unicode
		  restricted: restricted
]

{ #category : 'properties' }
PCRE2UnicodeData class >> same: first as: second unicode: unicode restricted: restricted [

	(restricted and: [ first asInteger < 128 ~= (second asInteger < 128) ]) ifTrue: [ ^ false ].
	^ self same: first as: second unicode: unicode
]

{ #category : 'registration' }
PCRE2UnicodeData class >> tables [

	^ Tables ifNil: [ PCRE2PharoUnicodeTables ]
]

{ #category : 'registration' }
PCRE2UnicodeData class >> tables: unicodeTables [
	"Answer general categories, case folding and digits from unicodeTables, or from the image's own when it is nil."

	Tables := unicodeTables
]

{ #category : 'properties' }
PCRE2UnicodeData class >> turkishEquivalents: code [

	(#( 73 305 ) includes: code) ifTrue: [ ^ #( 73 305 ) ].
	(#( 105 304 ) includes: code) ifTrue: [ ^ #( 105 304 ) ].
	^ nil
]

{ #category : 'properties' }
PCRE2UnicodeData class >> unicodePosixPredicate: property caseless: caseless [

	| key |
	property = 'ascii' ifTrue: [ ^ [ :character | character asInteger < 128 ] ].
	property = 'alnum' ifTrue: [ ^ self predicateFor: 'Xan' caseless: caseless ].
	property = 'word' ifTrue: [ ^ [ :character | self isWord: character asInteger ] ].
	property = 'space' ifTrue: [ ^ [ :character | self isSpace: character asInteger ] ].
	property = 'blank' ifTrue: [ ^ [ :character | character asInteger = 9 or: [ self category: #zs includes: character asInteger ] ] ].
	property = 'graph' ifTrue: [ ^ [ :character | self isGraph: character asInteger ] ].
	property = 'print' ifTrue: [ ^ [ :character | self isPrint: character asInteger ] ].
	property = 'punct' ifTrue: [
			^ [ :character |
				  (self category: #p includes: character asInteger) or: [
					  character asInteger < 128 and: [ self category: #s includes: character asInteger ] ] ] ].
	property = 'xdigit' ifTrue: [
			^ [ :character |
				  | code |
				  code := character asInteger.
				  (code between: 48 and: 57) or: [
						  (code between: 65 and: 70) or: [
								  (code between: 97 and: 102) or: [
									  (code between: 16rFF10 and: 16rFF19) or: [
										  (code between: 16rFF21 and: 16rFF26) or: [ code between: 16rFF41 and: 16rFF46 ] ] ] ] ] ] ].
	key := (Dictionary newFrom: {
			        ('alpha' -> 'L').
			        ('lower' -> 'Ll').
			        ('upper' -> 'Lu').
			        ('digit' -> 'Nd').
			        ('cntrl' -> 'Cc') }) at: property ifAbsent: [ PCRE2UnsupportedFeature signal: 'POSIX class ' , property ].
	^ self predicateFor: key caseless: caseless
]
