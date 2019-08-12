desc "This task is called by the Heroku scheduler add-on"
task :test_scheduler => :environment do
  puts "scheduler test"
  puts "it works."
end

require 'rexml/document'

task :alert_rain => :environment do
    users = User.all
    users.each do |user|
        user_id = user.user_id
        user_location_id = user.location_id
        user_location = Location.find_by(id: user_location_id)
        pref_id = user_location.prefid
        pref_name = user_location.name
        area_name = user_location.detail

        if pref_id > 0 && pref_id < 10
        pref_id = "0#{pref_id}"
        end
        uri = URI.parse("https://www.drk7.jp/weather/xml/#{pref_id}.xml")
        xml = Net::HTTP.get(uri)
        doc = REXML::Document.new(xml)

        ENV['TZ'] = 'Asia/Tokyo'
        d = Time.new;
        date = d.strftime("%Y/%m/%d") # 日付
        
        xpath = "weatherforecast/pref/area[@id='#{area_name}']/info[@date='#{date}']"
        
        weather = doc.elements[xpath + '/weather'].text # 天気（例：「晴れ」）

        if weather.include?("晴")
            per00to06 = doc.elements[xpath + '/rainfallchance/period[1]'].text # 0-6時の降水確率
            per06to12 = doc.elements[xpath + '/rainfallchance/period[2]'].text # 6-12時の降水確率
            per12to18 = doc.elements[xpath + '/rainfallchance/period[3]'].text # 12-18時の降水確率
            per18to24 = doc.elements[xpath + '/rainfallchance/period[4]'].text # 18-24時の降水確率

            a = "00 ~ 06時 #{per00to06} %\n"
            b = "06 ~ 12時 #{per06to12} %\n"
            c = "12 ~ 18時 #{per12to18} %\n"
            d = "18 ~ 24時 #{per18to24} %"
            main = "#{date}\n#{pref_name}#{area_name}の天気は\n「 #{weather} 」\n"
            ms = "#{main}#{a}#{b}#{c}#{d}"

            message = {
                type: 'text',
                text: "#{ms}"
            }
            client = Line::Bot::Client.new { |config|
                config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
                config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
            }
            response = client.push_message(user_id, message)
            p response
        end
    end
end