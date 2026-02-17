package commit

import (
	"github.com/jesseduffield/lazygit/pkg/config"
	. "github.com/jesseduffield/lazygit/pkg/integration/components"
)

var GenerateCommitMessage = NewIntegrationTest(NewIntegrationTestArgs{
	Description:  "Generate commit message via configured AI command",
	ExtraCmdArgs: []string{},
	Skip:         false,
	SetupConfig: func(config *config.AppConfig) {
		config.GetUserConfig().Git.Commit.AICommitMessage.Command = "sh ./generate_commit_message.sh"
	},
	SetupRepo: func(shell *Shell) {
		shell.CreateFile("file", "file content")
		shell.CreateFile("generate_commit_message.sh", "#!/bin/sh\ncat >/dev/null\nprintf '%s' '{\"version\":\"1\",\"title\":\"feat: generated title\",\"description\":\"generated body line 1\\ngenerated body line 2\"}'\n")
		shell.RunCommand([]string{"chmod", "+x", "generate_commit_message.sh"})
	},
	Run: func(t *TestDriver, keys config.KeybindingConfig) {
		t.Views().Files().
			Focus().
			PressPrimaryAction().
			Press(keys.Files.CommitChanges)

		t.ExpectPopup().CommitMessagePanel().
			Title(Equals("Commit summary")).
			Type("old summary")

		t.Views().CommitMessage().Press(keys.CommitMessage.GenerateCommitMessage)

		t.ExpectPopup().Alert().
			Title(Equals("Generate commit message")).
			Content(Contains("overwrite")).
			Confirm()

		t.ExpectPopup().CommitMessagePanel().
			Content(Equals("feat: generated title")).
			SwitchToDescription().
			Content(Equals("generated body line 1\ngenerated body line 2"))
	},
})
