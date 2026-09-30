# frozen_string_literal: true

require 'fileutils'

# TODO add spec tests
RSpec.describe B4U do
  # Heads up, DO NOT pass rspec as a lint task else it will recursively run this test
  dummy_config = { 'required-files' => nil, 'linters' => [{ 'name' => 'echo', 'command' => 'echo "Hello world"' }] }.freeze
  missing_file_config = { 'required-files' => ['missing_file.rb'], 'linters' => [{ 'name' => 'echo', 'command' => 'echo "Hello world"' }] }.freeze
  failing_linter_config = { 'required-files' => nil, 'linters' => [{ 'name' => 'echo', 'command' => 'exit 1' }] }.freeze

  it 'has a version number' do
    expect(B4U::VERSION).not_to be nil
  end

  it 'throws an error if required files are missing' do
    expect { B4U.lint(config: missing_file_config) }.to raise_error(StructureError)
  end

  it 'can run a successful lint task' do
    expect(B4U.lint(config: dummy_config)).to be nil
  end

  it 'can run a failing link task' do
    expect { B4U.lint(config: failing_linter_config) }.to raise_error(SystemExit)
  end

  describe 'run_if' do
    tmp_dir = File.expand_path('tmp', __dir__)
    sentinel = File.join(tmp_dir, 'ran')

    before { FileUtils.mkdir_p(tmp_dir) }
    after { FileUtils.rm_rf(tmp_dir) }

    def config(*linters)
      { 'required-files' => nil, 'linters' => linters }
    end

    skipped = { 'name' => 'skipped', 'command' => 'exit 1', 'run_if' => { 'command' => 'false' } }.freeze
    passing = { 'name' => 'passing', 'command' => 'true' }.freeze
    failing = { 'name' => 'failing', 'command' => 'exit 1' }.freeze

    it 'reports the skip count when steps are skipped' do
      expect { B4U.lint(config: config(skipped, passing)) }.to output(/All linters passed! \(1 skipped\)/).to_stdout
    end

    it 'keeps the original summary when nothing is skipped' do
      expect { B4U.lint(config: config(passing)) }.to output(/All linters passed!\n\z/).to_stdout
    end

    it 'still fails when another step fails' do
      expect { B4U.lint(config: config(skipped, passing, failing)) }
        .to raise_error(SystemExit).and output.to_stdout
    end

    it 'fails the hook when a condition is broken' do
      broken = { 'name' => 'broken', 'command' => 'true', 'run_if' => { 'command' => 'exit 127' } }
      expect { B4U.lint(config: config(broken)) }
        .to raise_error(SystemExit).and output(/❌ - broken \(run_if error\)/).to_stdout
    end

    {
      'a string' => 'true',
      'a list' => [{ 'command' => 'true' }],
      'missing command' => { 'description' => 'no command' },
      'blank command' => { 'command' => '  ' },
      'non-string description' => { 'command' => 'true', 'description' => 1 },
      'an unknown key' => { 'comand' => 'true' },
      'an unknown key alongside command' => { 'command' => 'true', 'descripton' => 'typo' },
    }.each do |label, run_if|
      it "rejects run_if with #{label} before running anything" do
        first = { 'name' => 'first', 'command' => "touch '#{sentinel}'" }
        bad = { 'name' => 'bad', 'command' => 'true', 'run_if' => run_if }
        expect { B4U.lint(config: config(first, bad)) }
          .to raise_error(ConfigError, /Step 'bad'/).and output.to_stdout
        expect(File).not_to exist(sentinel)
      end
    end
  end
end
