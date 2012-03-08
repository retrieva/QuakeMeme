#!/usr/bin/env ruby
# coding: utf-8

require 'net/http'
require 'uri'
require 'rubygems'
require 'json'
require 'time'

USERNAME = ''
PASSWORD = ''

class SedueClient
  def initialize
    @host = "qmsedue"
    @port = "11153"
    @key_field = "id"
    @fields = ["id", "time", "user", "text", "hashtags"]
    @timeout = 5
  end
  def register(h)
    xml = []
    xml << "<add immediate=\"true\"><doc>\n"
    #xml << "<add><doc>\n"
    @fields.each { |field|
      val = h[field]
      val = "" if val.nil?
      val = val.to_s.strip
      docxml =<<END
  <field name="#{field}"><![CDATA[#{val}]]></field>
END
      xml << docxml
    }
    xml << "</doc></add>"
    xml = xml.join
    puts xml
    post(h[@key_field], xml)
  end
  def post(id, buf)
    url = "http://#{@host}:#{@port}/update?key_field=#{@key_field}"
    content_type = "text/xml; charset=utf-8"
    begin
      connection.request_post(url, buf, {"Content-type" => content_type }) { |res|
        next if res.code.to_i == 200
        puts "Register fail: key_field=#{id}"
        puts res.body
      }
    rescue => ex
      p ex
      p ex.class
    rescue Timeout::Error => ex
      p ex
      p ex.class
    end
  end
  def connection
    @connection ||= begin
      c = Net::HTTP.new(@host, @port)
      raise "Failed to connect to #{@host}:#{@port}" if c.nil?
      c.read_timeout = @timeout
      c
    end
  end
end

module Net
  class HTTPResponse
    def each_line(rs = "\n")
      stream_check
      while line = @socket.readuntil(rs)
        yield line
      end
      self
    end
  end
end

uri = URI.parse('http://stream.twitter.com/1/statuses/filter.json')
Net::HTTP.start(uri.host, uri.port) do |http|
  request = Net::HTTP::Post.new(uri.request_uri)
  request.set_form_data('track' => ARGV[0])
  request.basic_auth(USERNAME, PASSWORD)
  http.request(request) do |response|
    raise 'Response is not chuncked' unless response.chunked?
    response.each_line("\r\n") do |line|
      begin
        status = JSON.parse(line)
      rescue
        #puts "parse error: #{line}"
        next
      end
      next unless status['text']

      sedue = {}
      sedue['id'] = status['id']
      sedue['time'] = Time.parse(status['created_at']).to_i.to_s
      user = status['user']
      sedue['user'] = user['screen_name']
      sedue['text'] = status['text']
      tags = ''
      status['entities']['hashtags'].each { |h|
        if tags.empty?
          tags = h['text']
        else
          tags = tags + "|" + h['text']
        end
      }
      sedue['hashtags'] = tags

      cln = SedueClient.new
      cln.register(sedue)
    end
  end
end
