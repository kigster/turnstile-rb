[![Gem Version](https://badge.fury.io/rb/turnstile-rb.svg)](https://badge.fury.io/rb/turnstile-rb)
[![Build Status](https://travis-ci.org/kigster/turnstile-rb.svg?branch=master)](https://travis-ci.org/kigster/turnstile-rb)
[![Maintainability](https://api.codeclimate.com/v1/badges/8031931b7924461f6a90/maintainability)](https://codeclimate.com/github/kigster/turnstile-rb/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8031931b7924461f6a90/test_coverage)](https://codeclimate.com/github/kigster/turnstile-rb/test_coverage)

# Turnstile

The goal of this gem is to provide near real time tracking and reporting on the number of users currently online and accessing given application.  It requires that the reporting layer is able to uniquely identify each user. You may also add one another dimension to the tracking, such as i.e. a _platform_ — a coded device or device type the user is using. 

For example, you might support platforms: `ios`, `android`, `macos`, `windows`, etc.

The gem uses [Redis](http://redis.io/) in order to keep track of the data, and can operate in either the **online* mode** (tracking users from a Rack Middleware) or **offline mode**, by taling an application file log file and searching for a particular pattern.

## Installation

Add this line to your application's Gemfile:

    $ gem install turnstile-rb
    $ turnstile --help

## Usage

The gem provides command line interface shown below:

 
### Description

Turnstile is a Redis-based library that can accurately track total number
of concurrent users accessing a web/API based server application. It can
break it down by "platform" or a device type, and returns data in JSON,
CSV of NAD formats. While user tracking may happen synchronously using a
Rack middleware, another method is provided that is based on log file
analysis, and can therefore be performed outside web server process.

### Usage

```
   # Tail the log file as a proper daemon, and optionally HTTP end point
   turnstile -f <file> [ --daemon ] [ --web PORT ] [ options ]

   # Add a single item and exit
   turnstile -a 'platform:ip:user'   [ options ]

   # Print the summary stats and exit
   turnstile -s [ json | csv | nad ] [ options ]
```

### Details

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
   
1. Format named `delimited`, which expects the following token in the
   log file:

       x-turnstile:platform:ip:user-identifier

   Where ':' (the delimiter) can be set via -l option, OR you can use one
   of the following formats: `json_formatted`, `pipe_formatted`,
   `comma_formatted`, `colon_formatted` (the default). The match is 
   performed on a string `x-turnstile`, other log lines are skipped.

2. Format `json_delimited`, which expects to find a single-line JSON
   Hash, containing keys `platform`, `ip_address`, and `user_id`. The match
   is performed on any log line containing string '`ip_address`', other
   lines are skipped.
 
3.  Format `custom` requires passing an additional flag `-c/--config
   file.rb`, which will be required, and which can define a matcher and
   assign it to the `Turnstile.config.custom_matcher` config variable.
   
Custom matcher is any object that responds to two methods:

 * `matches?(line)` — must return true if the line is to be used in token extraction, and
 * `tokenlize(line)` — must return a string of the form `platform:ip:user-id` as a result of parsing the `line`.

### Command Line Options

The following flags are available:

```
  Mode of Operation:
    -f, --file FILE                  Starts Turnstile in a file-tailing mode
                                      
    -s, --show [FORMAT]              Print current stats and exit. Optional 
                                     format can be "json" (default), "nad",
                                     "yaml", or "csv"
                                      
    -w, --web [PORT]                 Starts a Sinatra app on a given port
                                     offering /turnstile/<json|yaml> end point.
                                     Can be used with file tailing mode, or
                                     standalone. Default port is 9090
                                      
    -a, --add TOKEN                  Registers an event from the token, such as 
                                     "ios:123.4.4.4:32442". Use -l to customize
                                     the delimiter
                                      
    -p, --print-keys                 Prints all Turnstile keys in Redis
                                      
        --flushdb                    Wipes Redis database, and exit
                                      
  Tailing log file:
    -d, --daemonize                  Daemonize to watch the logs
                                      
    -b, --read-backwards [LINES]     Like tail, read last LINES lines
                                     instead of tailing from the end
                                      
    -F, --format FORMAT              Log file format (see above)
                                      
    -l, --delimiter CHAR             Forces "delimited" file type, and 
                                     uses CHAR as the delimiter
                                      
    -c, --config FILE                Ruby config file that can define the
                                     custom matcher, supporting arbitrary 
                                     complex logs

  Redis Server:
    -r, --redis-url URL              Redis server URL
        --redis-host HOST            Redis server host
        --redis-port PORT            Redis server port
        --redis-db DB                Redis server db
        --hiredis                    Use hiredis high performance library

  Miscellaneous:
    -i, --idle-sleep SECONDS         When no work was detected, pause the 
                                     threads for several seconds.
    -v, --verbose                    Print status to stdout
    -t, --trace                      Enable trace mode
    -h, --help                       Show this message

```

To summarize, you can run `turnstile` in order to:

 * start a daemon to tail a log file
 * optionally start a Sinatra web server on port 9090, that returns aggregated results to `/turnstile/json`
 * to print results
 * to print all redis keys
 * to reset all data
 * to add new data

### Data Collection and Reporting 

Turnstile contains two primary parts: data collection and reporting.  

Data collection may happen in two way:

  1. Synchronously — in real time — i.e. from a web request
  2. Or asynchronously — by "tailing" the logs on your servers

*Synchronous tracking* is accurate, supports sampling, but introduces a run-time dependency into your application middleware stack that might not be desirable. This is how `Rack::Attack` and other similar middleware operates. Luckily, there is a better way. 

*Asynchronous tracking* has a slight initial setup overhead and it requires a consistently formatted log file that includes lines with the platform, IP and user ID for ALL users at least some of the time. This method introduces zero run-time overhead, as the data collection happens outside of the web request in a standalone daemon, that simply tails your log files. 

On high performance web applications it is highly recommended to employ the *asynchronous tracking* via the log file, and possibly — a custom matcher.

> NOTE: as of Turnstile version 3, you can define a [custom matcher](#custom-matcher) in a ruby-syntax configuration file. Coupled with `-F custom` you are then able to parse arbitrary complex log files and extract the three tokens needed by Turnstile: the `platform` enum type, `IP addresss`, and `User ID`. 


#### Real Time Tracking API

With Real Time tracking you can use sampling to _estimate_ the number of online users. 

 * To possibly use sampling, use the ```Turnstile::Tracker#track``` method.
 * To store and analyze 100% of your data use ```Turnstile::Tracker#add```. 

**Example:**

```ruby
@tracker = Turnstile::Tracker.new

user_id   = 12345
platform  = 'desktop'
ip        = '224.247.12.4'

# register user
@tracker.add(user_id, platform, ip)

# or you can add a colon-delimited string token:
@tracker.add_token("ios:172.2.5.3:39898098098")

# or you with a custom delimiter:
@tracker.add_token("ios|172.2.5.3|39898098098", '|')

```

Without any further calls to ```track()``` method for this particular user/platform/ip combination, the user  is considered _online_ for 60 seconds.  Each subsequent call to ```track()``` resets the TTL.

#### Offline Log Parsing by "Tailing Logs"

If adding latency to a web request is not desirable, another option is to run Turnstile ```turnstile``` process as a daemon on each application server. The daemon "tails" the `production.log` file (or any other file), while scanning for lines matching a particular configurable pattern, and then extracting `user id`, `IP` and `platform` based on another configurable regular expression setting.

##### Data Structure

The logging approach expects that you print a special token into your log file, which contains three fields separated by a delimiter:

 * `x-turnstile` is a hardcoded string used in finding this token,
 * `platform` — ideally a short string, such as 'desktop', 'ios', 'android', etc
 * `remote IP` — is the IP address of the request
 * `user_id` — can be encoded, i.e. digest of user_id)
 
for example, a token such as this:

```
x-turnstile:desktop:125.4.5.13:3456
```

is colon-separated, and easily extractable from the log.

##### Log File Formats

Turnstile supports two primary formats:

 1. JSON format, where each **log line** contains the following JSON fields:
 
      ```json
      { "user_id"     :17344742,
        "platform"    :"iphone",
        "session_id"  :"4eKMZJ4nggzvkix29zpS", 
        "ip_address"  :"70.210.128.241"
      }
      ```
 
 2. Plain text format, where lines are space delimited, and the token is one of the fields of your log line, itself delimited using a configurable character.
 
      ```
      2017-10-06 11:03:21 x-turnstile|desktop|124.5.4.3|234324 GET /...
      ```

You can specify the file format using the `-t | --file-type` switch. 

Possible values are:

 * `json_formatted`
 * `pipe_delimited`
 * `colon_delimited`
 * `comma_delimited`
 
You can also pass the token delimiter on the command line, `-D | --delimiter "," ` in which case the `delimited` file type is used, with your custom delimiter. 

> NOTE: Default format is **`pipe_delimited`**.

<a name="custom-matcher"></a>

### Custom Log Matchers

> This feature is only available in Turnstile version 3.0 or later.

To be able to tail a structured log file in any format, create a ruby config file, and pass it with `-c <file>`.

For example, below we'll define a custom matcher that extracts our token from a CSV log file.

```
# config/custom_csv_matcher.rb

# This matcher extracts platform, UID and IP from the following CSV string:
# 2018-05-02 21:51:44.031,25928,3997,th-M4wDQM4w0,web,j5v-dzg0J,69.181.72.240,e2b1be795372c385c92a7df420752992

class CSVMatcher
  def tokenize(line)
    words = line.split(',')
    platform, ip, uid = [ words[4], web[6], web[7] ]
    [platform, ip, uid].join(':')
  end

  def matches?(line)
    line =~ /x-rqst/
  end
end

Turnstile.config.custom_matcher = CSVMatcher.new
```

The above matcher defines a very simple block that receives a string as input, and returns a string which is a combined value from:

```ruby
"#{platform}:#{ip}:#{user_id}"
``` 

For example, `ios:1.4.54.25:fg7988798779` is a valid token. Note that IP addresses are not necessary for the purposes of tracking, and can be omitted.

With the above file defined, we would start turnstile's collector process as follows, tailing the CSV log file:

```bash
turnstile -f log/production_log.csv -F custom -c config/custom_csv_matcher.rb
```

### Examples

For example:

```bash
> gem install turnstile

> turnstile -v -f log/production/log -t json_formatted | \
    tee -a /var/log/turnstile.log

> turnstile -v -f log/production/log -h 127.0.0.1 -p 6432 | \
    tee -a /var/log/turnstile.log

2014-04-12 05:16:41 -0700: updater:flush        - nothing to flush, sleeping 6s..
2014-04-12 05:16:41 -0700: updater:queue        - nothing in the queue, sleeping 5s...
2014-04-12 05:16:41 -0700: log-reader           - starting to tail file log....
2014-04-12 05:16:46 -0700: updater:queue        - nothing in the queue, sleeping 5s...
2014-04-12 05:16:53 -0700: updater:flush        - nothing to flush, sleeping 6s..
2014-04-12 05:16:56 -0700: updater:queue        - (     0.65ms) caching [746] keys locally
2014-04-12 05:16:59 -0700: updater:flush        - (    91.73ms) flushing cache with [602] keys
2014-04-12 05:17:05 -0700: updater:flush        - nothing to flush, sleeping 6s..
^Ctrl-C
```

Note that ideally you should run ```turnstile``` on all app servers, for completeness, and because this does not incur any additional cost for the application (as user tracking is happening outside web request).

### Reporting

Once the tracking information is sent, the data can be queried.  

If you used sampling, then you should query using ```Turnstile::Observer``` class that provides  exprapolation of the results based on sample size configuration.

```ruby
# Return data for sampled users and the summary 
Turnstile::Observer.new.stats
# => { stats: { 
        total: 3, 
        platforms: 2 }, 
       users: [ { uid: 1, platform: 'desktop', ip: '123.2.4.54' }, ... ]
```

If you did not use sampling, you can get some answers from the`Turnstile::Adapter` class:

```ruby
Turntstile::Adapter.new.fetch
# => [ { uid: 213, :platform: 'desktop', '123.2.4.54' }, { uid: 215, ... } ]
```

You can also request an aggregate results, suitable for sending to graphing systems or displaying on a dashboard:

```ruby
Turntstile::Adapter.new.aggregate
# => { 'desktop' => 234, 'ios' => 3214, ...,  'total' => 4566 }
```

### Summary Printing

### JSON and CSV

Use the following syntax:

```bash
# To see JSON summary:
turnstile -s json

# Or, for CSV
turnstile -s csv
```



#### Circonus NAD

We use Circonus to collect and graph data. You can use ```turnstile```
to dump the current aggregate statistics from redis to standard output,
which is a tab-delimited format consumable by the nad daemon.

(below output is formatted to show tabs as aligned for readability).

```bash
> turnstile -s

turnstile.iphone     n     383
turnstile.ipad       n	    34
turnstile.android    n     108
turnstile.ipod_touch n      34
turnstile.unknown    n      36
turnstile.total      n     595
```


## TODO:

* Allow users of the gem to easier customize log reader to fit their own custom log files
* Export configuration into a YAML file and load from there by defaul
* Refactor commands to have a single ```turnstile``` CLI with sub-commands ```watch``` and ```report```.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/turnstile/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
