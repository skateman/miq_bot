require "spec_helper"

RSpec.describe PullRequestMonitor::RepoProcessor do
  describe ".process" do
    let(:github) { stub_github_service }
    let(:git) do
      stub_git_service.tap do |git|
        expect(git).to receive(:checkout).with("master")
        expect(git).to receive(:pull)
      end
    end

    it "creates a PR branch record" do
      repo = create(:repo)
      pr   = double("GitHub PR", :number => 1)
      stub_github_prs(github, [pr]).twice

      expect(PullRequestMonitor::PrBranchRecord).to receive(:create).with(repo, pr, "prs/1/head")

      described_class.process(repo)
    end

    it "skips an existing PR branch record" do
      repo      = create(:repo, :branches => [create(:pr_branch)])
      pr_number = repo.pr_branches.first.pr_number
      pr        = double("GitHub PR old", :number => pr_number)
      stub_github_prs(github, [pr]).twice

      expect(PullRequestMonitor::PrBranchRecord).to_not receive(:create)

      described_class.process(repo)
    end

    it "prunes stale PR branch record" do
      repo      = create(:repo, :branches => [create(:pr_branch)])
      pr_number = repo.pr_branches.first.pr_number
      stub_github_prs(github, []).twice

      described_class.process(repo)

      expect(repo.branches.reload).to be_blank
    end
  end
end
