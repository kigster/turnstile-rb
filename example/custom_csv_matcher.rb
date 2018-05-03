# For a log file of the following format:
#
# I│2018-05-02 07:47:58.770 │ 25887 ⤶  3997 │ th-M4wDQDbBB  ❯❯❯ time:     73.8ms  ✔  │ x-rqst │ src=android │ uid=0xFFFFD978998789 │ ip=47.23.6.197  │ sess=BGHSsdCsX5VvsN1jLsAR             │ REQ GET    │ 200 │ /api/v3/dashboard
# I│2018-05-02 21:51:43.925 │ 29122 ⤶  3997 │ th-7lxrgeJZA  ❯❯❯ time:     80.6ms  ✔  │ x-rqst │ src=android │ uid=0xF9909808f90809 │ ip=47.21.6.197  │ sess=BGHSsdCsX5VvsN1jLsAR             │ REQ GET    │ 200 │ /api/v4/stuff
#
module Application
  class CSVLogFormat
    def token_from(line)
      platform = line.scan(/src=(\w*)/).flatten.first
      ip       = line.scan(/ip=(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/).flatten.first
      uid      = line.scan(/sess=(\w*)/).flatten.first

      [platform, ip, uid].join(':')
    end

    def matches?(line)
      line =~ /x-rqst/
    end
  end
end

Turnstile.config.custom_matcher = Application::CSVLogFormat.new
