module Turnstile
  VERSION     = '3.0.0'

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
  file. Or, you can run turnstile to print the current aggregated stats 
  in several supported formats, such as JSON.
 
  When Turnstile is used to tail the log files, ideally you should 
  start turnstile daemon on each app sever that's generating log file, 
  or be content with the effects of sampling. 

  Note that the IP address is not required to track uniqueness. Only 
  platform and UID are used. Also note that custom formatter can be 
  specified in a config file to parse arbitrary complex log lines.
  EOF

  NS = "x-turnstile|#{VERSION.gsub(/\./,'')}".freeze
end
