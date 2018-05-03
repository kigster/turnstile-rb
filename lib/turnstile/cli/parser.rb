require 'optparse'
require 'colored2'
require 'forwardable'

require 'turnstile/version'

module Turnstile
  module CLI
    class Parser
      extend Forwardable
      def_delegators :@system, :stdout, :stdin, :stderr

      attr_accessor :options, :argv, :system


      def initialize(argv, system)
        self.system  = system
        self.argv    = argv.dup
        self.options = Hashie::Mash.new
        self.argv << '-h' if argv.empty?
      end


      def parse
        begin
          OptionParser.new do |opts|
            opts.banner = "Usage:\n".bold.magenta +
              "     # Tail the log file as a proper daemon\n".bold.black +
              "     turnstile -f <file> [ --daemon ]  [ options ]\n\n".yellow +

              "     # Add a single item and exit\n".bold.black +
              "     turnstile -a 'platform:ip:user'   [ options ]\n\n".yellow +

              "     # Print the summary stats and exit\n".bold.black +
              "     turnstile -s [ json | csv | nad ] [ options ]\n\n".yellow

            opts.separator 'Description:'.bold.magenta
            opts.separator '   ' + ::Turnstile::DESCRIPTION.gsub(/\n/, "\n   ")

            opts.separator 'Tailing log file:'.bold.magenta
            opts.on('-f', '--file FILE', 'File to monitor') do |file|
              options[:file] = file
            end

            opts.on('-p', '--read-backwards [LINES]',
                    'Used with -f mode, and allows re-processing last N',
                    'lines in that file instead of tailing the end') do |lines|
              options[:tail] = lines ? lines.to_i : -1
            end

            opts.on('-F', '--format FORMAT',
                    'Specifies the format of the log file. ',
                    'Supported Choices: ' + 'json_formatted, pipe_delimited,'.blue.bold,
                    'comma_delimited, colon_delimited, delimited'.blue.bold,
                    '(using the delimiter set with -l), ',
                    'and finally, ' + 'custom'.blue.bold + ', which can be defined',
                    'via ' + 'Turnstile::Configuration'.bold.blue) do |format|
              options[:filetype] = format
            end
            opts.on('-l', '--delimiter CHAR',
                    'Forces "delimited" file type, and uses ',
                    'the character in the argument as the delimiter') do |v|
              options[:delimiter] = v
            end

            opts.on('-c', '--config FILE', 'Ruby config file that can define ',
                    'the custom matcher, allowing arbitrary complex log',
                    'format parsing. Teach Turnstile how to extract three',
                    'tokens from a single line of text using custom_matcher') do |file|
              options[:config_file] = file
            end

            opts.separator "\nRedis Server:".bold.magenta

            opts.on('-r', '--redis-url URL', 'Redis server URL') { |host| Turnstile.config.redis_url = host }
            opts.on('--redis-host HOST', 'Redis server host') { |host| Turnstile.config.redis_host = host }
            opts.on('--redis-port PORT', 'Redis server port') { |port| Turnstile.config.redis_port = port }
            opts.on('--redis-db DB', 'Redis server db') { |db| Turnstile.config.redis_db = db }

            opts.separator "\nMode of Operation:".bold.magenta
            opts.on('-d', '--daemonize', 'Daemonize to watch the logs') { |v| options[:daemonize] = true }

            opts.on('-s', '--show [FORMAT]',
                    'Print current stats and exit. Optional format can be',
                    'json (default), nad, yaml, or csv') do |v|
              options[:show]        = true
              options[:show_format] = (v || 'json').to_sym
            end

            opts.on('-a', '--add TOKEN',
                    'Registers an event from the token, such as ',
                    '"ios:123.4.4.4:32442". Use -l to customize delimiter.') do |v|
              options[:token] = v
            end

            opts.on('--flushdb', 'Wipes Redis database, and exit.') do |v|
              options[:flushdb] = true
            end
            opts.on('--print-keys', 'Prints all Turnstile keys in Redis') do |v|
              options[:print_keys] = true
            end

            opts.separator "\nMiscellaneous:".bold.magenta

            opts.on('-i', '--idle-sleep SECONDS',
                    'When no work was detected, pause the ',
                    'threads for several seconds.') do |v|
              options[:flush_interval] = v.to_i
            end

            opts.on('-v', '--verbose', 'Print status to stdout') { |v| options[:verbose] = true }
            opts.on('-t', '--trace', 'Enable trace mode') { |v| options[:trace] = true }
            opts.on_tail('-h', '--help', 'Show this message') do
              puts opts
              return
            end
          end.parse!(argv)
          options
        rescue OptionParser::MissingArgument => e
          stderr.puts 'Invalid Usage: ' + e.message.red
          nil
        rescue Exception => e
          stderr.puts e.message.bold.red
          nil
        end
      end

    end
  end
end
