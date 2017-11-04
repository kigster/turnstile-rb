require 'optparse'
require 'colored2'

require 'turnstile/version'
require 'turnstile/parser'

module Turnstile


  class Runner
    attr_reader :argv, :stdin, :stdout, :stderr, :kernel

    # Allow everything fun to be injected from the outside while defaulting to normal implementations.
    def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
      @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
    end

    def execute!
      exit_code = begin

        Colored2.disable! unless stdout.tty?

        $stderr = stderr
        $stdin  = stdin
        $stdout = stdout

        Turnstile::Parser.new(argv, self).parse

        # Thor::Base#start does not have a return value, assume success if no exception is raised.
        0
      rescue StandardError => e
        # The ruby interpreter would pipe this to STDERR and exit 1 in the case of an unhandled exception
        b = e.backtrace
        @stderr.puts("#{b.shift}: #{e.message} (#{e.class})")
        @stderr.puts(b.map { |s| "\tfrom #{s}" }.join("\n"))
        1
      rescue SystemExit => e
        e.status
      ensure
        $stderr = STDERR
        $stdin  = STDIN
        $stdout = STDOUT
      end

      # Proxy our exit code back to the injected kernel.
      @kernel.exit(exit_code)
    end
  end
end

module Turnstile

end
