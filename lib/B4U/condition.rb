require 'open3'

class Condition
  KEYS = %w[command description].freeze
  # 126 = found but not executable, 127 = command not found
  BROKEN_EXIT_CODES = [126, 127].freeze

  attr_reader :command, :description

  def initialize(command:, description: nil)
    @command = command
    @description = description
  end

  # Builds a Condition from a step's run_if config, or returns nil if the step has none
  def self.from_config(run_if, step:)
    return if run_if.nil?
    raise config_error(step, "run_if must be a mapping with a 'command'") unless run_if.is_a?(Hash)

    unknown_keys = run_if.keys - KEYS
    raise config_error(step, "unknown run_if key(s): #{unknown_keys.join(', ')}") unless unknown_keys.empty?

    command, description = run_if.values_at('command', 'description')
    raise config_error(step, "run_if must be a mapping with a 'command'") unless command.is_a?(String) && !command.strip.empty?
    raise config_error(step, 'run_if description must be a string') unless description.nil? || description.is_a?(String)

    new(command:, description:)
  end

  def self.config_error(step, msg)
    ConfigError.new("Step '#{step}': #{msg}")
  end
  private_class_method :config_error

  def label
    description || command
  end

  # Returns [:met | :unmet | :broken, console_output]
  def evaluate
    console_output, status = Open3.capture2e(command)
    if status.success?
      [:met, console_output]
    elsif BROKEN_EXIT_CODES.include?(status.exitstatus)
      [:broken, console_output]
    else
      [:unmet, console_output]
    end
  rescue SystemCallError => e
    [:broken, e.message]
  end
end
