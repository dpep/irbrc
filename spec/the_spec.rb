describe "Irbrc" do

  describe ".parse_repo" do
    subject { Irbrc.parse_repo(str) }

    let(:str) { "origin  git@bitbucket.org:danielpepper/bit123.git (fetch)" }

    it "parses the repo" do
      is_expected.to eq(
        source: 'bitbucket',
        repo: 'danielpepper/bit123.git',
      )
    end

    context "with both push and fetch branches" do
      let(:str) do
        [
          "origin git@github.com:dpep/rb_irbrc.git (fetch)",
          "origin git@github.com:dpep/rb_irbrc_push.git (push)",
        ].join("\n")
      end

      it "parses the fetch repo" do
        is_expected.to eq(
          source: 'github',
          repo: 'dpep/rb_irbrc.git',
        )
      end
    end
  end
end
