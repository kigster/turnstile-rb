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
            opts.banner = ' '

            opts.separator 'DESCRIPTION:'.bold.magenta
            opts.separator '   ' + ::Turnstile::GEM_DESCRIPTION.gsub(/\n/, "\n   ").strip
            opts.separator ''

            opts.separator "USAGE:\n".bold.magenta +
                "   # Tail the log file as a proper daemon\n".bold.black +
                "   turnstile -f <file> [ --daemon ]  [ options ]\n\n".yellow +

                "   # Add a single item and exit\n".bold.black +
                "   turnstile -a 'platform:ip:user'   [ options ]\n\n".yellow +

                "   # Print the summary stats and exit\n".bold.black +
                '   turnstile -s [ json | csv | nad ] [ options ]'.yellow

            opts.separator ''
            opts.separator 'DETAILS:'.bold.magenta
            opts.separator '   ' + ::Turnstile::DESCRIPTION.gsub(/\n/, "\n   ").strip

            opts.separator ''
            opts.separator 'OPTIONS:'.bold.magenta


            opts.separator "\n  Mode of Operation:".bold.green
            opts.on('-f', '--file FILE',
                    'Starts Turnstile in a file-tailing mode',
                    ' ') do |file|
              options[:file] = file
            end

            opts.on('-s', '--show [FORMAT]',
                    'Print current stats and exit. Optional ',
                    'format can be "json" (default), "nad",',
                    '"yaml", or "csv"', ' ') do |v|
              options[:show]        = true
              options[:show_format] = (v || 'json').to_sym
            end

            opts.on('-w', '--web [PORT]',
                    'Starts a Sinatra app on a given port',
                    'offering /turnstile/<json|yaml> end point.',
                    'Can be used with file tailing mode, or',
                    'standalone. Default port is ' +
                        ::Turnstile::DEFAULT_PORT.to_s,
                    ' '
                    ) do |v|
              options[:web] = true
              Turnstile.config.port = v.to_i if v
            end

            opts.on('-a', '--add TOKEN',
                    'Registers an event from the token, such as ',
                    '"ios:123.4.4.4:32442". Use -l to customize',
                    'the delimiter', ' ') do |v|
              options[:token] = v
            end

            opts.on('-p', '--print-keys', 'Prints all Turnstile keys in Redis', ' ') do |v|
              options[:print_keys] = true
            end

            opts.on('--flushdb', 'Wipes Redis database, and exit', ' ') do |v|
              options[:flushdb] = true
            end


            opts.separator '  Tailing log file:'.bold.green

            opts.on('-d', '--daemonize', 'Daemonize to watch the logs', ' ') do |v|
              options[:daemonize] = true
            end

            opts.on('-b', '--read-backwards [LINES]',
                    'Like tail, read last LINES lines',
                    'instead of tailing from the end', ' ') do |lines|
              options[:tail] = lines ? lines.to_i : -1
            end

            opts.on('-F', '--format FORMAT',
                    'Log file format (see above)', ' ') do |format|
              options[:filetype] = format
            end
            opts.on('-l', '--delimiter CHAR',
                    'Forces "delimited" file type, and ',
                    'uses CHAR as the delimiter', ' ') do |v|
              options[:delimiter] = v
            end

            opts.on('-c', '--config FILE',
                              'Ruby config file that can define the',
                              'custom matcher, supporting arbitrary ',
                              'complex logs') do |file|
              options[:config_file] = file
            end

            opts.separator "\n  Redis Server:".bold.green

            opts.on('-r', '--redis-url URL', 'Redis server URL') { |host| Turnstile.config.redis_url = host }
            opts.on('--redis-host HOST', 'Redis server host') { |host| Turnstile.config.redis_host = host }
            opts.on('--redis-port PORT', 'Redis server port') { |port| Turnstile.config.redis_port = port }
            opts.on('--redis-db DB', 'Redis server db') { |db| Turnstile.config.redis_db = db }
            opts.on('--hiredis', 'Use hiredis high performance library') do |_value|
              begin
                require 'redis/connection/hiredis'
              rescue LoadError => e
                raise HiredisDriverNotFound, "Can not use hiredis driver: #{e.message}"
              end
              Turnstile.config.redis_use_hiredis = true
            end

            opts.separator "\n  Miscellaneous:".bold.green

            opts.on('-i', '--idle-sleep SECONDS',
                    'When no work was detected, pause the ',
                    'threads for several seconds.') do |v|
              options[:flush_interval] = v.to_i
            end

            opts.on('-v', '--verbose', 'Print status to stdout') { |v| options[:verbose] = true }
            opts.on('-t', '--trace', 'Enable trace mode') do |v|
              options[:trace]        = true
              Turnstile.config.trace = true
            end
            opts.on_tail('-h', '--help', 'Show this message') do
              puts opts
              return
            end
          end.parse!(argv)
          options
        rescue OptionParser::MissingArgument => e
          terr 'Invalid Usage: ' + e.message.red, stderr
          nil
        rescue Exception => e
          terr e.message.bold.red, stderr
          nil
        end
      end

    end
  end
end
