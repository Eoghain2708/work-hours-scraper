require "net/http"
require "json"
require "time"
require "fileutils"
require "dotenv"
require_relative "cache"

class Client
  LOGIN_URL = ENV["LOGIN_URL"]

  # @params  date
  # returns json of employees for the week of __date__
  def get_employees(date)
    login_token = login_and_get_token
    roster_uri = URI(ENV["ROSTER_URL"])
    roster_uri.query = URI.encode_www_form(date: date.to_s)
    roster_request = Net::HTTP::Get.new(roster_uri)
    roster_request["synergy-login-token"] = login_token
    roster_response = Net::HTTP.start(roster_uri.hostname, roster_uri.port, use_ssl: true) do |http|
      http.request(roster_request)
    end
    
    begin
      body = JSON.parse(roster_response.body)
    rescue => e 
      puts e
    end

    body["employees"]
  end
  
  private
  # Sends env login data to the REST endpoint for the login page if loginToken does not exist in cache or is expired, then writes that token
  # and its expiryTime to cache, then returns the token.
  # If loginToken is already present in cache, simply returns the token.
  def login_and_get_token
    return cached_token if cached_token

    uri = URI(LOGIN_URL)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"

    request.body = {
      loginIp: "",
      password: ENV["PASS"],
      userId: ENV["USER_ID"],
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    body = JSON.parse(response.body)

    
    Cache.write("token.json",
    JSON.pretty_generate(
      loginToken: body["loginToken"],
      expiryTime: body["expiryTime"]
    ))


    body["loginToken"]
  end

  def cached_token
    return nil unless Cache.exist?("token.json")
    return nil if Cache.empty?("token.json")
    cache = JSON.parse(Cache.read("token.json"))

    return nil if Time.now.to_i * 1000 >= cache["expiryTime"]

    cache["loginToken"]
  end
end