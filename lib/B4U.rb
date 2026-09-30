# frozen_string_literal: true

require_relative 'B4U/runner'
require_relative 'B4U/string_methods'
require_relative 'B4U/condition'
require_relative 'B4U/linter'
require_relative 'B4U/version'
require_relative 'B4U/error'


module B4U
  def self.lint(config:)
    ProjectChecker.ensure_project_root!(config['required-files']) unless config['required-files'].nil?
    puts "Project structure valid, running #{config['linters'].count} linting steps...".green
    linters = config['linters'].map do |linter|
      Linter.new(
        name: linter['name'],
        command: linter['command'],
        ignore: linter.fetch('ignore', false),
        run_if: Condition.from_config(linter['run_if'], step: linter['name']),
        )
    end
    puts "Before you do that we are just going to check: #{linters.map(&:name)}".cyan.bold

    runner = LinterRunner.new(linters)
    skipped = runner.run_all
    summary = skipped.zero? ? 'All linters passed!' : "All linters passed! (#{skipped} skipped)"
    puts summary.bg_green
  end

  class ProjectChecker
    def self.ensure_project_root!(required_files)
      puts 'Checking project structure...'.cyan
      missing_files = required_files.reject { |file| File.exist?(file) }
      raise StructureError.new(files: missing_files, msg: "Missing project files: #{missing_files.join(', ')}") unless missing_files.empty?
    end
  end
end
