module Turnstile
  VERSION     = '2.0.1'

  GEM_DESCRIPTION = <<-EOF
  Turnstile is a Redis-based library that can accurately track total number of concurrent
  users accessing a web/API based server application. It can break it down by "platform"
  or a device type, and returns data in JSON, CSV of NAD formats. While user tracking
  may happen synchronously using a Rack middleware, another method is provided that is
  based on log file analysis, and can therefore be performed outside web server process.
  EOF

  DESCRIPTION = <<-EOF
  Turnstile can run as a daemon, in which mode it monitors a given log file. 
  Alternatively, turnstile binary can be used to print current stats, and even
  add new data into the registry.  
 
  If you are using Turnstile to tail log files, make sure you run on each app sever
  that's generating log files.
  EOF

end
