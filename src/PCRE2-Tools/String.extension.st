Extension { #name : 'String' }

{ #category : '*PCRE2-Tools' }
String >> openPerlCompatibleRegexDebugger [
	"Open a standalone PCRE2 debugger using myself as the pattern, leaving the subject to be typed into the window."

	^ PCRE2DebuggerPresenter openOnPattern: self
]

{ #category : '*PCRE2-Tools' }
String >> openPerlCompatibleRegexDebuggerOn: subjectString [
	"Open a standalone PCRE2 debugger using myself as the pattern."

	^ PCRE2DebuggerPresenter openOnPattern: self subject: subjectString
]
