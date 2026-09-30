require 'open3'

class Linter
  attr_reader :name, :command, :ignore, :run_if

  def initialize(name:, command:, ignore: false, run_if: nil)
    @name = name
    @command = command
    @ignore = ignore
    @run_if = run_if
  end

  # Returns :passed, :skipped or :ignored, raises LinterError on a blocking failure
  def run
    if run_if
      result, console_output = run_if.evaluate
      return skip if result == :unmet
      return broken_condition(console_output) if result == :broken
    end

    console_output, status = Open3.capture2e(command)
    if status.success?
      puts "✅ - #{name}".green
      :passed
    elsif ignore
      puts "❌ - #{name} (ignored)".magenta
      :ignored
    else
      puts "❌ - #{name}".red
      raise LinterError.new(linter: name, console_output:)
    end
  end

private

  def skip
    puts "🦘 - #{name} (skipped: #{run_if.label})".yellow
    :skipped
  end

  # A broken run_if is a config mistake, so it blocks even when the step is ignored
  def broken_condition(console_output)
    puts "❌ - #{name} (run_if error)".red
    raise LinterError.new(linter: name, console_output:)
  end
end
