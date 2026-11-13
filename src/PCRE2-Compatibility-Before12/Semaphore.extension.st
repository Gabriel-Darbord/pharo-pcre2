Extension { #name : 'Semaphore' }

{ #category : '*PCRE2-Compatibility-Before12' }
Semaphore >> waitTimeoutMilliseconds: anInteger [
	"Wait on this semaphore for up to the given number of milliseconds, then timeout.
	Return true if the deadline expired, false otherwise."

	^ self waitTimeoutMSecs: anInteger
]
