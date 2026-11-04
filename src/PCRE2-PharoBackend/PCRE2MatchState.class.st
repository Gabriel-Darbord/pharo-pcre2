"
One point in a match: the subject position, the capture vector, the list of tasks still to run, the current mark, and the scopes that assertions, alternations and subroutines unwind to.

The engine copies a state whenever it takes a choice, so abandoning a path costs nothing and no node has to undo its own work.
"
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
		'assertions',
		'subjectText',
		'capturesStorage'
	],
	#category : 'PCRE2-PharoBackend',
	#package : 'PCRE2-PharoBackend'
}

{ #category : 'matching' }
PCRE2MatchState >> accepted [

	^ accepted = true
]

{ #category : 'accessing' }
PCRE2MatchState >> accepted: boolean [

	accepted := boolean
]

{ #category : 'accessing' }
PCRE2MatchState >> alternations [

	^ alternations
]

{ #category : 'accessing' }
PCRE2MatchState >> alternations: frames [

	alternations := frames
]

{ #category : 'matching' }
PCRE2MatchState >> appendTasks: tail [

	| nodes link |
	nodes := OrderedCollection new.
	link := tasks.
	[ link isNotNil ] whileTrue: [
			nodes add: link first.
			link := link second ].
	self tasks: tail.
	nodes reverseDo: [ :node | self push: node ]
]

{ #category : 'accessing' }
PCRE2MatchState >> assertions [

	^ assertions
]

{ #category : 'accessing' }
PCRE2MatchState >> assertions: frames [

	assertions := frames
]

{ #category : 'accessing' }
PCRE2MatchState >> captures [

	^ captures
]

{ #category : 'accessing' }
PCRE2MatchState >> captures: anArray [

	captures := anArray.
	capturesStorage := nil
]

{ #category : 'diagnostics' }
PCRE2MatchState >> capturesStorage [
	"The memory the capture vector takes, measured once. Its size never changes while a match runs, and the heap limit asks for this on every step."

	^ capturesStorage ifNil: [ capturesStorage := captures sizeInMemory ]
]

{ #category : 'initialization' }
PCRE2MatchState >> initialize [

	pendingDepth := 0
]

{ #category : 'matching' }
PCRE2MatchState >> lastCapture [

	^ lastCapture ifNil: [ 0 ]
]

{ #category : 'accessing' }
PCRE2MatchState >> lastCapture: number [

	lastCapture := number
]

{ #category : 'accessing' }
PCRE2MatchState >> mark [

	^ mark
]

{ #category : 'accessing' }
PCRE2MatchState >> mark: aString [

	mark := aString
]

{ #category : 'accessing' }
PCRE2MatchState >> marks [

	^ marks
]

{ #category : 'accessing' }
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

	| marksCount capturesSize |
	marksCount := marks ifNil: [ 0 ] ifNotNil: [ marks fourth ].
	capturesSize := self capturesStorage.
	^ self class byteSizeOfInstance + capturesSize + (pendingDepth * (160 + capturesSize)) + (marksCount * 64)
]

{ #category : 'accessing' }
PCRE2MatchState >> pendingDepth [

	^ pendingDepth
]

{ #category : 'matching' }
PCRE2MatchState >> pop [
	"The task list is a chain of pairs, read here by index rather than through first and second because this runs for every node the engine executes."

	| node |
	node := tasks at: 1.
	tasks := tasks at: 2.
	pendingDepth := pendingDepth - 1.
	^ node
]

{ #category : 'accessing' }
PCRE2MatchState >> position [

	^ position
]

{ #category : 'accessing' }
PCRE2MatchState >> position: anInteger [

	position := anInteger
]

{ #category : 'copying' }
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

{ #category : 'accessing' }
PCRE2MatchState >> subjectText [

	^ subjectText
]

{ #category : 'accessing' }
PCRE2MatchState >> subjectText: aSubject [

	subjectText := aSubject
]

{ #category : 'accessing' }
PCRE2MatchState >> subroutines [

	^ subroutines
]

{ #category : 'accessing' }
PCRE2MatchState >> subroutines: frames [

	subroutines := frames
]

{ #category : 'accessing' }
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
