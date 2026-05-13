Extension { #name : 'String' }

{ #category : '*PCRE2-Tools' }
String >> openPerlCompatibleRegexDebuggerOn: subjectString [
	"Open a standalone PCRE2 debugger using myself as the pattern."

	^ PCRE2DebuggerPresenter openOnPattern: self subject: subjectString
]
