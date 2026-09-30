# frozen_string_literal: true

require 'fileutils'

RSpec.describe Condition do
  tmp_dir = File.expand_path('tmp', __dir__)

  before { FileUtils.mkdir_p(tmp_dir) }
  after { FileUtils.rm_rf(tmp_dir) }

  def write_script(path, body, executable: true)
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(executable ? 0o755 : 0o644, path)
  end

  describe '#evaluate' do
    it 'is met when the command exits 0' do
      expect(described_class.new(command: 'true').evaluate.first).to eq :met
    end

    it 'is unmet when the command exits 1' do
      expect(described_class.new(command: 'false').evaluate.first).to eq :unmet
    end

    it 'is unmet for other non-zero exit codes' do
      expect(described_class.new(command: 'exit 3').evaluate.first).to eq :unmet
    end

    it 'supports negation, mirroring "! git diff --staged --quiet"' do
      expect(described_class.new(command: '! false').evaluate.first).to eq :met
      expect(described_class.new(command: '! true').evaluate.first).to eq :unmet
    end

    it 'runs the step when a negated command errors (fail safe)' do
      expect(described_class.new(command: '! (exit 128)').evaluate.first).to eq :met
    end

    it 'is broken when the shell reports exit 127' do
      expect(described_class.new(command: 'exit 127').evaluate.first).to eq :broken
    end

    it 'is broken when the command does not exist, and captures the error' do
      result, output = described_class.new(command: 'b4u_no_such_command').evaluate
      expect(result).to eq :broken
      expect(output).not_to be_empty
    end

    it 'is broken when the script is not executable' do
      script = File.join(tmp_dir, 'not_executable.sh')
      write_script(script, 'exit 0', executable: false)
      result, output = described_class.new(command: script).evaluate
      expect(result).to eq :broken
      expect(output).not_to be_empty
    end

    it 'honours an executable script file' do
      pass = File.join(tmp_dir, 'pass.sh')
      skip = File.join(tmp_dir, 'skip.sh')
      write_script(pass, 'exit 0')
      write_script(skip, 'exit 1')
      expect(described_class.new(command: pass).evaluate.first).to eq :met
      expect(described_class.new(command: skip).evaluate.first).to eq :unmet
    end
  end

  describe '#label' do
    it 'uses the description when given' do
      expect(described_class.new(command: 'true', description: 'Ruby staged').label).to eq 'Ruby staged'
    end

    it 'falls back to the command' do
      expect(described_class.new(command: 'true').label).to eq 'true'
    end
  end
end
