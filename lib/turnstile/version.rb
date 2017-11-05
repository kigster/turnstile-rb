module Turnstile
  VERSION     = '2.2.0'

  GEM_DESCRIPTION = <<-EOF
  Turnstile is a Redis-based library that can accurately track total 
  number of concurrent users accessing a web/API based server application.
 
  It can break it down by "platform" or a device type, and returns data 
  in JSON, CSV of NAD formats. While user tracking may happen synchronously 
  using a Rack middleware, another method is provided that is based on log 
  file analysis, and can therefore be performed outside web server process.
  EOF

  DESCRIPTION = <<-EOF
  Turnstile can be run as a daemon, in which case it watches a given log 
  file. Or, you can run turnstile executable to print the current aggregated 
  stats in several supported formats.
 
  When Turnstile is used to tail the log files, please make sure that you
  start turnstile daemon on each app sever that's generating log file.
  EOF

  NS = "x-turnstile|#{VERSION.gsub(/\./,'')}".freeze
end
