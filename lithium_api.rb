require 'rest_client'
require 'awesome_print'
require 'yaml'
require 'json'
require 'active_support'

class Lithium
  class NoResponseError < Exception; end
  class LithiumError < Exception; end
  class MissingSessionKey < Exception; end

  attr_accessor :data, :session_key

  def initialize
    self.data ||= YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config', 'config.yml'))['lithium']
    self.session_key = nil
  end

  def get_session_key
    response = self.request("/authentication/sessions/login", :post, {"user.login" => self.data['login'], "user.password" => self.data['password']})
    self.session_key = response["value"]['$'] if response
  end

  def request(path, verb, query = {})
    url = "https://"
    url += self.data['domain']
    url += "/restapi/vc"

    query = query.merge({"restapi.response_format" => "json"})
    query = query.merge({"restapi.session_key" => self.session_key}) if self.session_key
ap "#{url}#{path}"
    ap query
    response = (verb == :get ? RestClient.get("#{url}#{path}?#{query.map{|k,v| "#{k}=#{v}"}.join('&')}") : RestClient.post("#{url}#{path}", query))

    self.parse(response)
  end

  def multipart_request(user_id, path, multipart = {})
    url = "https://"
    url += self.data['domain']
    url += "/restapi/vc"
    
    query = {}
    query = query.merge({"restapi.response_format" => "json"})
    query = query.merge({"credentials.identity_user" => "/users/id/#{user_id}"})
    query = query.merge({"restapi.session_key" => self.session_key}) if self.session_key
ap "#{url}#{path}"
    ap query
    response = RestClient.post("#{url}#{path}?#{query.map{|k,v| "#{k}=#{v}"}.join('&')}", multipart)

    self.parse(response)
  end



  def parse(json)
    json = JSON.parse(json)
    raise NoResponseError unless json['response']
    if json['response']['status'] == "error"
      raise LithiumError.new("[#{json['response']['error']["code"]}: #{json['response']['error']["message"]}]")
    end
    return json['response']
  end
end

