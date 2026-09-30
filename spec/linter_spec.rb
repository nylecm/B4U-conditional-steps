# frozen_string_literal: true

require 'fileutils'

RSpec.describe Linter do
  tmp_dir = File.expand_path('tmp', __dir__)
  sentinel = File.join(tmp_dir, 'ran')

  before { FileUtils.mkdir_p(tmp_dir) }
  after { FileUtils.rm_rf(tmp_dir) }

  def linter(command: 'true', ignore: false, run_if: nil)
    described_class.new(name: 'step', command:, ignore:, run_if:)
  end

  let(:met) { Condition.new(command: 'true', description: 'always') }
  let(:unmet) { Condition.new(command: 'false', description: 'never') }
  let(:broken) { Condition.new(command: 'exit 127') }

  it 'runs as before without run_if' do
    result = nil
    expect { result = linter.run }.to output("✅ - step\n").to_stdout
    expect(result).to eq :passed
  end

  it 'runs the step when the condition is met' do
    result = nil
    expect { result = linter(run_if: met).run }.to output("✅ - step\n").to_stdout
    expect(result).to eq :passed
  end

  it 'skips a failing step when the condition is unmet' do
    result = nil
    expect { result = linter(command: 'exit 1', run_if: unmet).run }
      .to output("🦘 - step (skipped: never)\n").to_stdout
    expect(result).to eq :skipped
  end

  it 'reports an unmet condition as skipped, not ignored, on ignore steps' do
    expect { linter(ignore: true, run_if: unmet).run }.to output(/🦘 - step \(skipped: never\)/).to_stdout
  end

  it 'does not run the step command when the condition is unmet' do
    expect { linter(command: "touch '#{sentinel}'", run_if: unmet).run }.to output.to_stdout
    expect(File).not_to exist(sentinel)
  end

  it 'runs the step command when the condition is met' do
    expect { linter(command: "touch '#{sentinel}'", run_if: met).run }.to output.to_stdout
    expect(File).to exist(sentinel)
  end

  it 'fails the step when the condition is broken' do
    missing = Condition.new(command: 'b4u_no_such_command')
    expect { linter(run_if: missing).run }
      .to raise_error(LinterError) { |error| expect(error.console_output).not_to be_empty }
      .and output("❌ - step (run_if error)\n").to_stdout
  end

  it 'fails a broken condition even on ignore steps' do
    expect { linter(ignore: true, run_if: broken).run }
      .to raise_error(LinterError)
      .and output("❌ - step (run_if error)\n").to_stdout
  end
end
