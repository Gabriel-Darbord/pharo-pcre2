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

{ #category : 'configuration' }
PCRE2CompileContext >> disableAutoPossessification [

	^ self optimize: PCRE2 optimizeAutoPossessOff
]

{ #category : 'configuration' }
PCRE2CompileContext >> disableDotstarAnchoring [

	^ self optimize: PCRE2 optimizeDotstarAnchorOff
]

{ #category : 'configuration' }
PCRE2CompileContext >> disableStartOptimization [

	^ self optimize: PCRE2 optimizeStartOff
]

{ #category : 'configuration' }
PCRE2CompileContext >> enableAutoPossessification [

	^ self optimize: PCRE2 optimizeAutoPossess
]

{ #category : 'configuration' }
PCRE2CompileContext >> enableDotstarAnchoring [

	^ self optimize: PCRE2 optimizeDotstarAnchor
]

{ #category : 'configuration' }
PCRE2CompileContext >> enableStartOptimization [

	^ self optimize: PCRE2 optimizeStart
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

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRAnyCRLF [
	"\R matches only CR, LF, or CRLF."

	^ self bsr: PCRE2 bsrAnyCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useBSRUnicode [
	"\R matches any Unicode line ending sequence."

	^ self bsr: PCRE2 bsrUnicode
]

{ #category : 'accessing' }
PCRE2CompileContext >> useCharacterTablesFromCurrentLocale [

	^ backend useCharacterTablesFromCurrentLocale
]

{ #category : 'configuration' }
PCRE2CompileContext >> useFullOptimization [

	^ self optimize: PCRE2 optimizationFull
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineAny [
	"Use any Unicode newline sequence."

	^ self newline: PCRE2 newlineAny
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineAnyCRLF [
	"Use CR, LF, or CRLF as newline sequences."

	^ self newline: PCRE2 newlineAnyCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineCR [

	^ self newline: PCRE2 newlineCR
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineCRLF [

	^ self newline: PCRE2 newlineCRLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineLF [

	^ self newline: PCRE2 newlineLF
]

{ #category : 'accessing' }
PCRE2CompileContext >> useNewlineNul [

	^ self newline: PCRE2 newlineNul
]

{ #category : 'configuration' }
PCRE2CompileContext >> useNoOptimization [

	^ self optimize: PCRE2 optimizationNone
]
