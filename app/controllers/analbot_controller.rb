class AnalbotController < ApplicationController
  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'rexml/document'

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
=begin
          when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
            response = client.get_message_content(event.message['id'])
            tf = Tempfile.open("content")
            tf.write(response.body)

          when Line::Bot::Event::MessageType::Location
            latitude = event.message['latitude'] # 緯度
            longitude = event.message['longitude'] # 経度
=end
            when Line::Bot::Event::MessageType::Text
              case event.message['text']
                when '使い方'
                  s = "〇使い方を知りたい。\n'使い方'と入力する。"
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
end
