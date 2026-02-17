package helpers

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTryRemoveHardLineBreaks(t *testing.T) {
	scenarios := []struct {
		name           string
		message        string
		autoWrapWidth  int
		expectedResult string
	}{
		{
			name:           "empty",
			message:        "",
			autoWrapWidth:  7,
			expectedResult: "",
		},
		{
			name:           "all line breaks are needed",
			message:        "abc\ndef\n\nxyz",
			autoWrapWidth:  7,
			expectedResult: "abc\ndef\n\nxyz",
		},
		{
			name:           "some can be unwrapped",
			message:        "123\nabc def\nghi jkl\nmno\n456\n",
			autoWrapWidth:  7,
			expectedResult: "123\nabc def ghi jkl mno\n456\n",
		},
	}
	for _, s := range scenarios {
		t.Run(s.name, func(t *testing.T) {
			actualResult := TryRemoveHardLineBreaks(s.message, s.autoWrapWidth)
			assert.Equal(t, s.expectedResult, actualResult)
		})
	}
}

func TestParseGenerateCommitMessageResponse(t *testing.T) {
	scenarios := []struct {
		name          string
		output        string
		expectedTitle string
		expectedBody  string
		expectedErr   string
	}{
		{
			name:          "valid response",
			output:        `{"version":"1","title":"feat: add parser","description":"adds parser for AI response","warnings":["w1"]}`,
			expectedTitle: "feat: add parser",
			expectedBody:  "adds parser for AI response",
		},
		{
			name:        "empty output",
			output:      "",
			expectedErr: "empty output",
		},
		{
			name:        "invalid json",
			output:      "not json",
			expectedErr: "invalid AI commit response",
		},
		{
			name:        "missing title",
			output:      `{"version":"1","description":"body only"}`,
			expectedErr: "missing title",
		},
		{
			name:        "multiline title",
			output:      "{\n\"version\":\"1\",\n\"title\":\"line 1\\nline 2\",\n\"description\":\"body\"\n}",
			expectedErr: "single line",
		},
		{
			name:        "unknown field",
			output:      `{"version":"1","title":"feat","description":"body","unknown":"value"}`,
			expectedErr: "invalid AI commit response",
		},
	}

	for _, s := range scenarios {
		t.Run(s.name, func(t *testing.T) {
			result, err := parseGenerateCommitMessageResponse(s.output)
			if s.expectedErr != "" {
				assert.Error(t, err)
				assert.ErrorContains(t, err, s.expectedErr)
				assert.Nil(t, result)
				return
			}

			assert.NoError(t, err)
			assert.Equal(t, s.expectedTitle, result.Title)
			assert.Equal(t, s.expectedBody, result.Description)
		})
	}
}
