# I│2018-05-02 07:47:58.770 │ 25887 ⤶  3997 │ th-M4wDQDbBB  ❯❯❯ time:     73.8ms  ✔  │ x-rqst │ src=android │ uid=logged-out       │ ip=47.213.226.197  │ sess=BGHSsdCsX5VvsN1jLsAR             │ REQ GET    │ 200 │ /api/v3/labor/jobs/wages                      (Api::V3::LaborController#wages_for_jobs) ◀— params={"start_date"=>"04/29/2018", "end_date"=>"05/05/2018", "jobs_ids"=>["1714727"]}
# I│2018-05-02 21:51:43.925 │ 29122 ⤶  3997 │ th-7lxrgeJZA  ❯❯❯ time:     80.6ms  ✔  │ x-rqst │ src=android │ uid=logged-out       │ ip=47.213.226.197  │ sess=BGHSsdCsX5VvsN1jLsAR             │ REQ GET    │ 200 │ /api/v4/locations/shifts                      (Api::V4::ShiftsController#for_locations) ◀— params={"start_at"=>"05/02/2018", "end_at"=>"05/02/2018", "for_dashboard"=>"true", "locations_ids"=>["1929"]}
#
custom_matcher do |line|
  if line =~ /x-rqst/
    platform = line.scan(/src=(\w*)/).flatten.first
    ip       = line.scan(/ip=(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/).flatten.first
    uid      = line.scan(/sess=(\w*)/).flatten.first
  end
  [platform, ip, uid].join(':')
end
