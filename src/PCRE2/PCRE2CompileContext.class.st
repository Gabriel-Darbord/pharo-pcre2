"
Public compile-context facade. Options, newline conventions, limits, and implementation-specific facilities are delegated to the selected backend. Obtain a context from a compiler so its backend and code-unit width agree.
"
Class {
	#name : 'PCRE2CompileContext',
	#superclass : 'PCRE2Context',
	#category : 'PCRE2',
	#package : 'PCRE2'
}

{ #category : 'testing' }
PCRE2CompileContext class >> isAbstract [

	^ self == PCRE2CompileContext
]

{ #category : 'accessing' }
PCRE2CompileContext >> addOptions: anInteger [

	^ backend addOptions: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr [

	^ backend bsr
]

{ #category : 'accessing' }
PCRE2CompileContext >> bsr: anInteger [

	backend bsr: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> characterTables [

	^ backend characterTables
]

{ #category : 'accessing' }
PCRE2CompileContext >> characterTables: aPCRE2CharacterTables [

	backend characterTables: aPCRE2CharacterTables
]

{ #category : 'accessing' }
PCRE2CompileContext >> checkSettingResult: resultCode [

	^ backend checkSettingResult: resultCode
]

{ #category : 'accessing' }
PCRE2CompileContext >> clearCharacterTables [

	^ backend clearCharacterTables
]

{ #category : 'accessing' }
PCRE2CompileContext >> compilerClass [

	^ backend compilerClass
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableAutoPossessification [

	^ backend disableAutoPossessification
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableDotstarAnchoring [

	^ backend disableDotstarAnchoring
]

{ #category : 'accessing' }
PCRE2CompileContext >> disableStartOptimization [

	^ backend disableStartOptimization
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableAutoPossessification [

	^ backend enableAutoPossessification
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableDotstarAnchoring [

	^ backend enableDotstarAnchoring
]

{ #category : 'accessing' }
PCRE2CompileContext >> enableStartOptimization [

	^ backend enableStartOptimization
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternCompiledLength [

	^ backend maxPatternCompiledLength
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternCompiledLength: anInteger [

	backend maxPatternCompiledLength: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternLength [

	^ backend maxPatternLength
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxPatternLength: anInteger [

	backend maxPatternLength: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind [

	^ backend maxVarLookbehind
]

{ #category : 'accessing' }
PCRE2CompileContext >> maxVarLookbehind: anInteger [

	backend maxVarLookbehind: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> newline [

	^ backend newline
]

{ #category : 'accessing' }
PCRE2CompileContext >> newline: anInteger [

	backend newline: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimizationDirectives [

	^ backend optimizationDirectives
]

{ #category : 'accessing' }
PCRE2CompileContext >> optimize: directive [

	backend optimize: directive
]

{ #category : 'accessing' }
PCRE2CompileContext >> options [

	^ backend options
]

{ #category : 'accessing' }
PCRE2CompileContext >> options: anInteger [

	backend options: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> parensNestLimit [

	^ backend parensNestLimit
]

{ #category : 'accessing' }
PCRE2CompileContext >> parensNestLimit: anInteger [

	backend parensNestLimit: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> privateCopy [

	^ backend privateCopy
]

{ #category : 'accessing' }
PCRE2CompileContext >> removeOptions: anInteger [

	^ backend removeOptions: anInteger
]

{ #category : 'accessing' }
PCRE2CompileContext >> requireSupportedFeature: featureName since: versionString when: aBoolean [

	^ backend requireSupportedFeature: featureName since: versionString when: aBoolean
]

{ #category : 'accessing' }
PCRE2CompileContext >> restoreAfterStartup [

	backend restoreAfterStartup
]

{ #category : 'accessing' }
PCRE2CompileContext >> setBSR: value [

	^ backend setBSR: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setCharacterTables: characterTablesOrNil [

	^ backend setCharacterTables: characterTablesOrNil
]

{ #category : 'accessing' }
PCRE2CompileContext >> setMaxPatternCompiledLength: value [

	^ backend setMaxPatternCompiledLength: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setMaxPatternLength: value [

	^ backend setMaxPatternLength: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setMaxVarLookbehind: value [

	^ backend setMaxVarLookbehind: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setNewline: value [

	^ backend setNewline: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setOptimize: directive [

	^ backend setOptimize: directive
]

{ #category : 'accessing' }
PCRE2CompileContext >> setOptions: value [

	^ backend setOptions: value
]

{ #category : 'accessing' }
PCRE2CompileContext >> setParensNestLimit: value [

	^ backend setParensNestLimit: value
]

{ #category : 'backends' }
PCRE2CompileContext >> useBSRAnyCRLF [
	"\R matches only CR, LF, or CRLF."

	^ self bsr: PCRE2 bsrAnyCRLF
]

{ #category : 'backends' }
PCRE2CompileContext >> useBSRUnicode [
	"\R matches any Unicode line ending sequence."

	^ self bsr: PCRE2 bsrUnicode
]

{ #category : 'accessing' }
PCRE2CompileContext >> useCharacterTablesFromCurrentLocale [

	^ backend useCharacterTablesFromCurrentLocale
]

{ #category : 'accessing' }
PCRE2CompileContext >> useFullOptimization [

	^ backend useFullOptimization
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineAny [
	"Use any Unicode newline sequence."

	^ self newline: PCRE2 newlineAny
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineAnyCRLF [
	"Use CR, LF, or CRLF as newline sequences."

	^ self newline: PCRE2 newlineAnyCRLF
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineCR [
	"Use carriage return as the newline sequence."

	^ self newline: PCRE2 newlineCR
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineCRLF [
	"Use CRLF as the newline sequence."

	^ self newline: PCRE2 newlineCRLF
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineLF [
	"Use line feed as the newline sequence."

	^ self newline: PCRE2 newlineLF
]

{ #category : 'backends' }
PCRE2CompileContext >> useNewlineNul [
	"Use NUL as the newline sequence."

	^ self newline: PCRE2 newlineNul
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNoOptimization [

	^ backend useNoOptimization
]
