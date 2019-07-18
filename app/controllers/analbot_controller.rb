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

          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              # text: event.message['text']
              text: '＊ <- It\'s an anal.'
            }
=begin
          when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
            response = client.get_message_content(event.message['id'])
            tf = Tempfile.open("content")
            tf.write(response.body)

          when Line::Bot::Event::MessageType::Location
            latitude = event.message['latitude'] # 緯度
            longitude = event.message['longitude'] # 経度
=end
            case event.message['text']
            when '天気', 'てんき'
              uri = URI.parse('https://www.drk7.jp/weather/xml/40.xml')
              xml = Net::HTTP.get(uri)
              doc = REXML::Document.new(xml)

              xpath = 'weatherforecast/pref/area[2]/info[2]'
              weather = doc.elements[xpath + '/weather'].text # 天気（例：「晴れ」）
              per00to06 = doc.elements[xpath + '/rainfallchance/period[1]'].text # 0-6時の降水確率
              per06to12 = doc.elements[xpath + '/rainfallchance/period[2]'].text # 6-12時の降水確率
              per12to18 = doc.elements[xpath + '/rainfallchance/period[3]'].text # 12-18時の降水確率
              per18to24 = doc.elements[xpath + '/rainfallchance/period[4]'].text # 18-24時の降水確率

              ms = "お前の居場所特定したわ m9^p^\n" 
                    + "今日は #{weather} や！\n"
                    + "00 ~ 06時 #{per00to06} %\n"
                    + "06 ~ 12時 #{per06to12} %\n"
                    + "12 ~ 18時 #{per12to18} %\n"
                    + "18 ~ 24時 #{per18to24} %\n"
              message = {
                type: 'text',
                text: "#{ms}"
              }
            
            end
          end
          client.reply_message(event['replyToken'], message)
        end
    }  
    head :ok
  end
end
