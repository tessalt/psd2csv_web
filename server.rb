require 'rubygems'
require 'sinatra'
require 'psd'
require 'csv'
require 'json'
require 'oauth2'
require "google_drive"
require "yaml"
require "sixarm_ruby_magic_number_type"

require_relative "./lib/psdfile"
require_relative "./lib/spreadsheet"

enable :sessions

puts ENV['RACK_ENV']

if ENV['RACK_ENV'] == 'production'
  CONFIG['CLIENTID'] = ENV['CLIENTID'] 
  CONFIG['CLIENTSECRET'] = ENV['CLIENTSECRET']
else
  CONFIG = YAML.load_file("config.yml") unless defined? CONFIG
end


client = OAuth2::Client.new(
  CONFIG['CLIENTID'], CONFIG['CLIENTSECRET'],
  :site => "https://accounts.google.com",
  :token_url => "/o/oauth2/token",
  :authorize_url => "/o/oauth2/auth")

get "/" do
  erb :index
end

get "/auth" do
  auth_url = client.auth_code.authorize_url(
    :redirect_uri => redirect_uri,
    :scope => "https://www.googleapis.com/auth/drive https://docs.google.com/feeds/ https://docs.googleusercontent.com/ https://spreadsheets.google.com/feeds/")
  redirect auth_url
end

get '/oauth2callback' do
  auth_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  session[:drive] = GoogleDrive.login_with_oauth(auth_token)
  redirect "/upload"
end

get "/upload" do
  erb :upload
end    

post "/upload" do 
  tempfile = params['file'][:tempfile]
  filetype = File.magic_number_type(tempfile)
  if filetype == :adobe_photoshop
    psd = PsdFile.new(tempfile)
    spreadsheet = SpreadSheet.new(session[:drive], params['file'][:filename], psd.rows)
    return spreadsheet.sheet.human_url
  else 
    return 'Please upload only .psd files'
  end
end

def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/oauth2callback'
  uri.query = nil
  uri.to_s
end