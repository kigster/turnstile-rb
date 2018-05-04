module Turnstile
  VERSION     = '3.0.1'
  DEFAULT_PORT = 9090

  GEM_DESCRIPTION = <<-EOF
Turnstile is a Redis-based library that can accurately track total number
of concurrent users accessing a web/API based server application. It can
break it down by "platform" or a device type, and returns data in JSON,
CSV of NAD formats. While user tracking may happen synchronously using a
Rack middleware, another method is provided that is based on log file
analysis, and can therefore be performed outside web server process.


  EOF

  DESCRIPTION = <<-EOF
Turnstile can be run as a daemon, in which case it watches a given log
file. Or, you can run turnstile to print the current aggregated stats in
several supported formats, such as JSON.

When Turnstile is used to tail the log files, ideally you should start
turnstile daemon on each app sever that's generating log file, or be
content with the effects of sampling.

Note that the IP address is not required to track uniqueness. Only
platform and UID are used. Also note that custom formatter can be
specified in a config file to parse arbitrary complex log lines.

For tailing a log files, Turnstile must first match a log line expected to
contain the tokens, and then extract is using one of the matchers. You can
specify which matcher to use depending on whether you can add Turnstile's 
tokens to your log or not. If you can, great! If not, implement your own 
custom matcher and great again.

The following matchers are available, and can be selected with -F:

  1. Format named "delimited", which expects the following token in the
     log file:

     x-turnstile:platform:ip:user-identifier

     Where ':' (the delimiter) can be set via -l option, OR you can use one
     of the following formats: "json_formatted", "pipe_formatted",
     "comma_formatted", "colon_formatted" (the default). The match is 
     performed on a string "x-turnstile", other log lines are skipped.

  2. Format "json_delimited", which expects to find a single-line JSON
     Hash, containing keys "platform", "ip_address", and "user_id". The match
     is performed on any log line containing string '"ip_address"', other
     lines are skipped.
    
 3.  Format "custom" requires passing an additional flag -c/--config
     file.rb, which will be required, and which can define a matcher and
     assign it to the `Turnstile.config.custom_matcher` config variable.


  EOF

  NS = "x-turnstile|#{VERSION.gsub(/\./,'')}".freeze
end
