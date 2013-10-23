require 'spec_helper'
require 'logger'
require 'bosh/dev/git_tagger'

module Bosh::Dev
  describe GitTagger do
    describe '#tag_and_push' do
      subject(:git_tagger) { described_class.new(Logger.new(nil)) }
      let(:sha)            { 'fake-sha' }
      let(:build_number)   { 'fake-build-id' }

      before { Open3.stub(capture3: success) }
      let(:success) { [nil, nil, instance_double('Process::Status', success?: true)] }

      context 'when tagging and pushing succeeds' do
        it 'tags stable_branch with jenkins build number' do
          Open3.should_receive(:capture3).with(
            'git', 'tag', '-a', 'stable-fake-build-id', '-m', 'ci-tagged', 'fake-sha').and_return(success)
          git_tagger.tag_and_push(sha, build_number)
        end

        it 'pushes tags' do
          Open3.should_receive(:capture3).with('git', 'push', 'origin', '--tags').and_return(success)
          git_tagger.tag_and_push(sha, build_number)
        end
      end

      context 'when tagging fails' do
        before { Open3.stub(:capture3).and_return(fail) }
        let(:fail) { [nil, nil, instance_double('Process::Status', success?: false)] }

        it 'raises an error' do
          expect {
            git_tagger.tag_and_push(sha, build_number)
          }.to raise_error(/Failed to tag/)
        end
      end

      context 'when pushing fails' do
        before { Open3.stub(:capture3).and_return(success, fail) }
        let(:fail) { [nil, nil, instance_double('Process::Status', success?: false)] }

        it 'raises an error' do
          expect {
            git_tagger.tag_and_push(sha, build_number)
          }.to raise_error(/Failed to push tags/)
        end
      end

      [nil, ''].each do |invalid|
        context "when sha is #{invalid.inspect}" do
          let(:sha) { invalid }

          it 'raises an error' do
            expect {
              git_tagger.tag_and_push(sha, build_number)
            }.to raise_error(ArgumentError, 'sha is required')
          end

          it 'does not execute any git commands' do
            Open3.should_not_receive(:capture3)
            expect { git_tagger.tag_and_push(sha, build_number) }.to raise_error
          end
        end
      end

      [nil, ''].each do |invalid|
        context "when build_number is #{invalid.inspect}" do
          let(:build_number) { invalid }

          it 'raises an error' do
            expect {
              git_tagger.tag_and_push(sha, build_number)
            }.to raise_error(ArgumentError, 'build_number is required')
          end

          it 'does not execute any git commands' do
            Open3.should_not_receive(:capture3)
            expect { git_tagger.tag_and_push(sha, build_number) }.to raise_error
          end
        end
      end
    end
  end
end
