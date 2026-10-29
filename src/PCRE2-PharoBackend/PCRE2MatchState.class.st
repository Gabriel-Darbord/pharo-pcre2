Class {
	#name : 'PCRE2MatchState',
	#superclass : 'Object',
	#instVars : [
		'position',
		'captures',
		'tasks',
		'mark',
		'pendingDepth',
		'subroutines',
		'alternations',
		'marks',
		'accepted',
		'lastCapture',
		'assertions'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2MatchState >> accepted [

	^ accepted = true
]

{ #category : 'matching' }
PCRE2MatchState >> accepted: boolean [

	accepted := boolean
]

{ #category : 'matching' }
PCRE2MatchState >> alternations [

	^ alternations
]

{ #category : 'matching' }
PCRE2MatchState >> alternations: frames [

	alternations := frames
]

{ #category : 'matching' }
PCRE2MatchState >> assertions [

	^ assertions
]

{ #category : 'matching' }
PCRE2MatchState >> assertions: frames [

	assertions := frames
]

{ #category : 'private' }
PCRE2MatchState >> captures [

	^ captures
]

{ #category : 'private' }
PCRE2MatchState >> captures: aValue [

	captures := aValue
]

{ #category : 'DFA matching' }
PCRE2MatchState >> dfaKey [

	| node keys |
	keys := OrderedCollection new.
	node := tasks.
	[ node isNotNil ] whileTrue: [
			keys add: node first dfaKey.
			node := node second ].
	^ {
		  position.
		  keys asArray }
]

{ #category : 'matching' }
PCRE2MatchState >> initialize [

	pendingDepth := 0
]

{ #category : 'matching' }
PCRE2MatchState >> lastCapture [

	^ lastCapture ifNil: [ 0 ]
]

{ #category : 'matching' }
PCRE2MatchState >> lastCapture: number [

	lastCapture := number
]

{ #category : 'private' }
PCRE2MatchState >> mark [

	^ mark
]

{ #category : 'private' }
PCRE2MatchState >> mark: aValue [

	mark := aValue
]

{ #category : 'matching' }
PCRE2MatchState >> marks [

	^ marks
]

{ #category : 'matching' }
PCRE2MatchState >> marks: frames [

	marks := frames
]

{ #category : 'diagnostics' }
PCRE2MatchState >> matchingStorageIn: seen [

	| size link |
	(seen includes: self) ifTrue: [ ^ 0 ].
	seen add: self.
	size := self sizeInMemory.
	(seen includes: captures) ifFalse: [
			seen add: captures.
			size := size + captures sizeInMemory ].
	{
		{
			tasks.
			2 }.
		{
			subroutines.
			2 }.
		{
			marks.
			3 }.
		{
			alternations.
			2 } } do: [ :entry |
			link := entry first.
			[ link isNotNil and: [ (seen includes: link) not ] ] whileTrue: [
					seen add: link.
					size := size + link sizeInMemory.
					link := link at: entry second ] ].
	link := tasks.
	[ link isNotNil ] whileTrue: [
			(seen includes: link first) ifFalse: [
					seen add: link first.
					size := size + link first runtimeStorageSize ].
			link := link second ].
	^ size
]

{ #category : 'diagnostics' }
PCRE2MatchState >> matchingStorageUpperBound [

	| marksCount |
	marksCount := marks ifNil: [ 0 ] ifNotNil: [ marks fourth ].
	^ self sizeInMemory + captures sizeInMemory + (pendingDepth * (160 + captures sizeInMemory)) + (marksCount * 64)
]

{ #category : 'matching' }
PCRE2MatchState >> pendingDepth [

	^ pendingDepth
]

{ #category : 'matching' }
PCRE2MatchState >> pop [

	| node |
	node := tasks first.
	tasks := tasks second.
	pendingDepth := pendingDepth - 1.
	^ node
]

{ #category : 'private' }
PCRE2MatchState >> position [

	^ position
]

{ #category : 'private' }
PCRE2MatchState >> position: aValue [

	position := aValue
]

{ #category : 'private' }
PCRE2MatchState >> postCopy [

	captures := captures copy
]

{ #category : 'matching' }
PCRE2MatchState >> push: aNode [

	tasks := {
		         aNode.
		         tasks }.
	pendingDepth := pendingDepth + 1
]

{ #category : 'matching' }
PCRE2MatchState >> subroutines [

	^ subroutines
]

{ #category : 'matching' }
PCRE2MatchState >> subroutines: frames [

	subroutines := frames
]

{ #category : 'private' }
PCRE2MatchState >> tasks [

	^ tasks
]

{ #category : 'matching' }
PCRE2MatchState >> tasks: aList [

	| link |
	tasks := aList.
	pendingDepth := 0.
	link := aList.
	[ link isNotNil ] whileTrue: [
			pendingDepth := pendingDepth + 1.
			link := link second ]
]
