# frozen_string_literal: true

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
end
