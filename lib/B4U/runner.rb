module B4U
  class LinterRunner
    def initialize(linters)
      @linters = linters
    end

    def run_all
      errors = @linters.map do |linter|
        Thread.new do
          begin
            linter.run
            nil
          rescue LinterError => e
            e
          end
        end
      end.map(&:join).filter_map(&:value)
      unless errors.empty?
        puts "\n"
        errors.each do |error|
          puts "Linter '#{error.linter}' failed with the following output:".bold
          puts error.console_output.red
        end
        exit 1
      end
    end
  end
end
