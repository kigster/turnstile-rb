[![Gem Version](https://badge.fury.io/rb/turnstile-rb.svg)](https://badge.fury.io/rb/turnstile-rb)
[![Build Status](https://travis-ci.org/kigster/turnstile-rb.svg?branch=master)](https://travis-ci.org/kigster/turnstile-rb)
[![Maintainability](https://api.codeclimate.com/v1/badges/8031931b7924461f6a90/maintainability)](https://codeclimate.com/github/kigster/turnstile-rb/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8031931b7924461f6a90/test_coverage)](https://codeclimate.com/github/kigster/turnstile-rb/test_coverage)

# Turnstile

The goal of this gem is to provide near real time tracking and reporting on the number of users currently online and accessing given application.  It requires that the reporting layer is able to uniquely identify each user and provide a unique identifier.  It may also optionally assign another dimension to the users accessing, such as, for example, _platform_ -- which in our case denotes how the user is accessing our application: from desktop browser, iOS app, Android app, mobile web, etc.  But any other partitioning schemee can be used, or none at all.

The gem uses (and depends on) a [Redis](http://redis.io/) instance in order to keep track of _unique_ users, and can operate in **online* mode (tracking users from a Rack Middleware) or **offline**, by taling a file log.

## Installation

Add this line to your application's Gemfile (Note that another gem with a competing name is on RubyGems, so you **must** specify the path below):

    gem 'turnstile-rb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install turnstile

## Usage

### Tracking 

Turnstile contains two primary parts: data collection and reporting.  

Data collection may happen in two way:

1. Synchronously — in real time — i.e. from a web request
2. Or asynchronously — by "tailing" the logs on your servers

Synchronous tracking is more accurate, supports sampling, but introduces a run-time dependency into your application middleware stack that might not be desirable.

Asynchronous tracking has a slight initial setup overhead, but has zero run-time overhead, as the data collection happens outside of the web request.

#### Real Time Tracking API

With Real Time tracking you can use sampling to _estimate_ the number of online users. 

 * To do sampling, use the ```Turnstile::Tracker#track``` method 
 * To store and analyze 100% of your data use ```Turnstile::Adapter#add```. 

**Example:**

```ruby
@turnstile = Turnstile::Adapter.new

user_id   = 12345
platform  = 'desktop'
ip        = '224.247.12.4'

# register user
@turnstile.add(user_id, platform, ip)
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
        "ip_address"  :"70.210.128.241",
        .... }
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

Note that ideally you should run ```turnstile``` on all app servers, for completeness, and because
this does not incur any additional cost for the application (as user tracking is happening outside web request).

### Reporting

Once the tracking information is sent, the data can be queried.  

If you used sampling, then you should query using ```Turnstile::Observer``` class that provides 
exprapolation of the results based on sample size configuration.
```ruby
# Return data for sampled users and the summary 
Turnstile::Observer.new.stats
# => { stats: { total: 3, platforms: 2 }, users: [ { uid: 1, platform: 'desktop', ip: '123.2.4.54' }, ... ]
```
If you did not use sampling, you can get some answers from the ```Turnstile::Adapter``` class:
```ruby
Turntstile::Adapter.new.fetch
# => [ { uid: 213, :platform: 'desktop', '123.2.4.54' }, { uid: 215, ... } ]
```
You can also request an aggregate results, suitable for sending to graphing systems or displaying on a dashboard:
```ruby
Turntstile::Adapter.new.aggregate
# => { 'desktop' => 234, 'ios' => 3214, ...,  'total' => 4566 }
```

## Circonus NAD Integration

We use Circonus to collect and graph data. You can use ```turnstile```
to dump the current aggregate statistics from redis to standard output,
which is a tab-delimited format consumable by the nad daemon.

(below output is formatted to show tabs as aligned for readability).

```ruby
> turnstile --summary

turnstile.iphone	   n      383
turnstile.ipad       n	    34
turnstile.android    n      108
turnstile.ipod_touch n      34
turnstile.unknown    n      36
turnstile.total      n      595
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
