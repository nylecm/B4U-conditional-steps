# frozen_string_literal: true

require_relative 'B4U/runner'
require_relative 'B4U/string_methods'
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
        )
    end
    puts "Before you do that we are just going to check: #{linters.map(&:name)}".cyan.bold

    runner = LinterRunner.new(linters)
    runner.run_all
    puts 'All linters passed!'.bg_green
  end

  class ProjectChecker
    def self.ensure_project_root!(required_files)
      puts 'Checking project structure...'.cyan
      missing_files = required_files.reject { |file| File.exist?(file) }
      raise StructureError.new(files: missing_files, msg: "Missing project files: #{missing_files.join(', ')}") unless missing_files.empty?
    end
  end
end
