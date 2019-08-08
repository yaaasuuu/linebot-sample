class AnalbotController < ApplicationController
  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'rexml/document'
  require 'open-uri'
  DISTANCE_API = "http://vldb.gsi.go.jp/sokuchi/surveycalc/surveycalc/bl2st_calc.pl?"

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
        error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
        when Line::Bot::Event::Message
          case event.type

            when Line::Bot::Event::MessageType::Location
              user_lat = event.message['latitude'] # 緯度
              user_long = event.message['longitude'] # 経度
              id = cal_address(user_long, user_lat)
              pref = Location.find_by(id: id).name
              area = Location.find_by(id: id).detail
              ms = "#{pref} #{area}"

            when Line::Bot::Event::MessageType::Text
              case event.message['text']
                when '使い方'
                  a = "〇今日の天気を知りたい。\n'天気'または'てんき'と入力する。\n"
                  b = "〇現在地を登録したい。\n位置情報を送ることで表示される天気の地点を指定できます。\n"
                  c = "★位置情報の送り方\n"
                  d = "1.左下の'+'を押し位置情報を選択する。\n"
                  e = "2.画面中央の'この位置を送信'を押す。"
                  ms = "#{a}#{b}#{c}#{d}#{e}"
                
                when '天気', 'てんき'
                  uri = URI.parse('https://www.drk7.jp/weather/xml/40.xml')
                  xml = Net::HTTP.get(uri)
                  doc = REXML::Document.new(xml)

                  ENV['TZ'] = 'Asia/Tokyo'
                  d = Time.new;
                  date = d.strftime("%Y/%m/%d") #日付
                  
                  xpath = "weatherforecast/pref/area[2]/info[@date='#{date}']"
                  
                  weather = doc.elements[xpath + '/weather'].text # 天気（例：「晴れ」）
                  per00to06 = doc.elements[xpath + '/rainfallchance/period[1]'].text # 0-6時の降水確率
                  per06to12 = doc.elements[xpath + '/rainfallchance/period[2]'].text # 6-12時の降水確率
                  per12to18 = doc.elements[xpath + '/rainfallchance/period[3]'].text # 12-18時の降水確率
                  per18to24 = doc.elements[xpath + '/rainfallchance/period[4]'].text # 18-24時の降水確率

                  a = "00 ~ 06時 #{per00to06} %\n"
                  b = "06 ~ 12時 #{per06to12} %\n"
                  c = "12 ~ 18時 #{per12to18} %\n"
                  d = "18 ~ 24時 #{per18to24} %"
                  main = "#{date} の天気は\n「 #{weather} 」\n"
                  ms = "#{main}#{a}#{b}#{c}#{d}"

                else
                  ms = "使い方を知りたいときは'使い方'と入力してください。"
              end
          end
        message = {
          type: 'text',
          text: "#{ms}"
        }
        client.reply_message(event['replyToken'], message)
      end 
    }  
    head :ok
  end

  def cal_address(user_long, user_lat)
    locations = Location.pluck('id', 'latitude', 'longitude')
    min = 100
    locations.each do |loc|
      id = loc[0]
      lat = loc[1]
      long = loc[2]
      d = distance(user_lat, user_long, lat, long).to_f
      d = (d/1000).round(6)
      if d < min
        min = d
        min_id = id
      end
    end
    return min
  end

  def distance(lat1, lng1, lat2, lng2)
    req_params = {
      outputType: "json",    # 出力タイプ
      ellipsoid:  "bessel",  # 楕円体
      latitude1:  lat1,      # 出発点緯度
      longitude1: lng1,      # 出発点経度
      latitude2:  lat2,      # 到着点緯度
      longitude2: lng2       # 到着点経度
    }
    req_param = req_params.map { |k, v| "#{k}=#{v}" }.join("&")
    result = JSON.parse(open(DISTANCE_API + req_param).read)
    result["OutputData"]["geoLength"]
  end
end
