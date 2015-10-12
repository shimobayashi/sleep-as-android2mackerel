#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'json'
require 'net/http'
require 'uri'

api_key = ENV['MACKEREL_API_KEY']
json = []

rows = []
CSV.foreach(ARGV[0]) {|row|
  rows << row
  next if rows.size < 3

  prev_dt = nil
  rows[0].each_with_index {|col, i|
    if col == 'Tz'
      ENV['TZ'] = rows[1][i]
    elsif col == 'From'
      prev_dt = DateTime.parse(rows[1][i])
    elsif col =~ /^(\d?\d):(\d\d)$/
      hour = $1.to_i
      min = $2.to_i
      dt = DateTime.new(prev_dt.year, prev_dt.month, prev_dt.day, hour, min)
      dt += 1 if dt < prev_dt
      prev_dt = dt

      epoch = Time.local(dt.year, dt.month, dt.day, dt.hour, dt.min).to_i
      movement = rows[1][i].to_f
      noise = rows[2][i].to_f

      #p dt
      #p epoch
      #p movement
      #p noise
      json << {
        name: 'test.sleep_as_android.movement',
        time: epoch,
        value: movement,
      }
      json << {
        name: 'test.sleep_as_android.noise',
        time: epoch,
        value: noise,
      }
    end
  }

  rows = []
}

#p json.to_json
uri = URI.parse('https://mackerel.io/api/v0/services/myha2/tsdb')
https = Net::HTTP.new(uri.host, uri.port)
https.use_ssl = true
req = Net::HTTP::Post.new(uri.request_uri)
req['Content-Type'] = 'application/json'
req['X-Api-Key'] = api_key
req.body = json.to_json
res = https.request(req)
p res
