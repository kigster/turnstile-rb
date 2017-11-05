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
              "     turnstile -f <file> [ --daemon ]  [ options ]\n".yellow +
              "     turnstile -s [ json | csv | nad ] [ options ]\n".yellow +
              "     turnstile -a 'platform:ip:user'   [ options ]\n".yellow

            opts.separator 'Description:'.bold.magenta
            opts.separator '   ' + ::Turnstile::DESCRIPTION.gsub(/\n/, "\n   ")

            opts.separator 'Log File Specification:'.bold.magenta
            opts.on('-f', '--file FILE', 'File to monitor') do |file|
              options[:file] = file
            end

            opts.on('-p', '--read-backwards [LINES]',
                    'Used with -f mode, and allows re-processing last N',
                    'lines in that file instead of tailing the end') do |lines|
              options[:tail] = lines ? lines : -1
            end

            opts.on('-F', '--format FORMAT',
                    'Specifies the format of the log file. ',
                    'Supported Choices:' + "\n    " +
                      "json_formatted, pipe_delimited, comma_delimited\ncolon_delimited, and just delimited.") do |format|
              options[:filetype] = format
            end

            opts.on('-l', '--delimiter CHAR',
                    'Forces "delimited" file type, and uses ',
                    'the character in the argument as the delimiter') do |v|
              options[:delimiter] = v
            end

            opts.separator "\nRedis Server:".bold.magenta

            opts.on('-r', '--redis-url URL', 'Redis server URL') { |host| Turnstile.config.redis_url = host }
            opts.on('--redis-host HOST', 'Redis server host') { |host| Turnstile.config.redis_host = host }
            opts.on('--redis-port PORT', 'Redis server port') { |port| Turnstile.config.redis_port = port }
            opts.on('--redis-db DB', 'Redis server db') { |db| Turnstile.config.redis_db = db }

            opts.separator "\nMode of Operation:".bold.magenta
            opts.on('-D', '--daemonize', 'Daemonize to watch the logs') { |v| options[:daemonize] = true }

            opts.on('-s', '--show [FORMAT]',
                    'Print current stats and exit. Optional format can be',
                    'json (default), nad, yaml, or csv') do |v|
              options[:show]        = true
              options[:show_format] = (v || 'json').to_sym
            end

            opts.on('-a', '--add TOKEN',
                    'Registers an event from the token, such as ',
                    '"ios:123.4.4.4:32442". Use -d to customize delimiter.') do |v|
              options[:token] = v
            end

            opts.on('--flushdb', 'Wipes Redis database, and exit.') do |v|
              options[:flushdb] = true
            end

            opts.separator "\nMiscellaneous:".bold.magenta

            opts.on('-i', '--idle-sleep SECONDS',
                    'When no work was detected, pause the ',
                    'threads for several seconds.') do |v|
              options[:flush_interval] = v.to_i
            end

            opts.on('-v', '--verbose', 'Print status to stdout') { |v| options[:verbose] = true }
            opts.on('-d', '--debug', 'Enable debug logging') { |v| options[:debug] = true }
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
