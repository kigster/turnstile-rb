require 'optparse'
require 'colored2'
require 'forwardable'

require 'turnstile/version'

module Turnstile
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
        opts.on('-t', '--file-type TYPE',
                'Either: json_formatted, pipe_delimited,',
                'or comma_delimited (default).') do |type|
          options[:filetype] = type
        end
        opts.on('-D', '--delimiter CHAR',
                'Forces "delimited" file type, and uses ',
                'the character in the argument as the delimiter') do |v|
          options[:delimiter] = v
        end
        opts.separator "\nRedis Server:".bold.magenta
        opts.on('-r', '--redis-url URL', 'Redis server URL') do |host|
          Turnstile.config.redis_url = host
        end
        opts.on('--redis-host HOST', 'Redis server host') do |host|
          Turnstile.config.redis_host = host
        end
        opts.on('--redis-port PORT', 'Redis server port') do |port|
          Turnstile.config.redis_port = port
        end
        opts.on('--redis-db DB', 'Redis server db') do |db|
          Turnstile.config.redis_db = db
        end
        opts.separator "\nMode of Operation:".bold.magenta
        opts.on('-d', '--daemonize', 'Daemonize to watch the logs') do |v|
          options[:daemonize] = true
        end
        opts.on('-s', '--summary [FORMAT]',
                'Print current stats and exit. Optional format can be',
                'json (default), nad, yaml, or csv') do |v|
          options[:summary]        = true
          options[:summary_format] = (v || 'json').to_sym
        end
        opts.on('-a', '--add TOKEN',
                'Registers an event from the token, such as ',
                '"ios:123.4.4.4:32442". Use -d to customize delimiter.') do |v|
          options[:add] = v
        end
        opts.separator "\nTiming Adjustments:".bold.magenta
        opts.on('-b', '--buffer-interval INTERVAL', 'Buffer for this many seconds') do |v|
          options[:buffer_interval] = v.to_i
        end
        opts.on('-i', '--flush-interval INTERVAL', 'Flush then sleep for this many seconds') do |v|
          options[:flush_interval] = v.to_i
        end
        opts.separator "\nMiscellaneous:".bold.magenta
        opts.on('-v', '--verbose', 'Print status to stdout') do |v|
          options[:debug] = true
        end
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          return
        end
      end.parse!(argv)

      if options[:summary]
        Turnstile::Summary.print(options[:summary_format] || :json, options[:delimiter])
      elsif options[:add]
        Turnstile::Tracker.new.add_token(options[:add], options[:delimiter] || ':')
        Turnstile::Summary.print(options[:summary_format] || :json)
      else
        Turnstile::Collector::Runner.new(options).run
      end

    rescue OptionParser::MissingArgument => e
      STDERR.puts e.message.bold.red
    rescue Exception => e
      STDERR.puts e.message.bold.red
    end
  end
end


