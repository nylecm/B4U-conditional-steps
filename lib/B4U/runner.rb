module B4U
  class LinterRunner
    def initialize(linters)
      @linters = linters
    end

    # Returns the number of skipped linters, exits 1 on any blocking failure
    def run_all
      results = @linters.map do |linter|
        Thread.new do
          begin
            linter.run
          rescue LinterError => e
            e
          end
        end
      end.map(&:value)
      errors = results.grep(LinterError)
      unless errors.empty?
        puts "\n"
        errors.each do |error|
          puts "Linter '#{error.linter}' failed with the following output:".bold
          puts error.console_output.red
        end
        exit 1
      end
      results.count(:skipped)
    end
  end
end
