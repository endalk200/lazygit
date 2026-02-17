package commit

import (
	"github.com/jesseduffield/lazygit/pkg/config"
	. "github.com/jesseduffield/lazygit/pkg/integration/components"
)

var GenerateCommitMessageMalformedResponse = NewIntegrationTest(NewIntegrationTestArgs{
	Description:  "Show an error when AI commit command returns malformed JSON",
	ExtraCmdArgs: []string{},
	Skip:         false,
	SetupConfig: func(config *config.AppConfig) {
		config.GetUserConfig().Git.Commit.AICommitMessage.Command = "sh ./generate_commit_message.sh"
	},
	SetupRepo: func(shell *Shell) {
		shell.CreateFile("file", "file content")
		shell.CreateFile("generate_commit_message.sh", "#!/bin/sh\ncat >/dev/null\nprintf '%s' 'not-json'\n")
		shell.RunCommand([]string{"chmod", "+x", "generate_commit_message.sh"})
	},
	Run: func(t *TestDriver, keys config.KeybindingConfig) {
		t.Views().Files().
			Focus().
			PressPrimaryAction().
			Press(keys.Files.CommitChanges)

		t.ExpectPopup().CommitMessagePanel().Title(Equals("Commit summary"))

		t.Views().CommitMessage().Press(keys.CommitMessage.GenerateCommitMessage)

		t.ExpectPopup().Alert().
			Title(Equals("Error")).
			Content(Contains("invalid AI commit response")).
			Confirm()

		t.ExpectPopup().CommitMessagePanel().Content(Equals(""))
	},
})
