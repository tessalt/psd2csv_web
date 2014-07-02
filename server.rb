require 'rubygems'
require 'sinatra'
require 'psd'
require 'csv'
require 'json'
require 'oauth2'
require "google_drive"
require "yaml"
require_relative "psdfile"
require_relative "spreadsheet"

enable :sessions

CONFIG = YAML.load_file("config.yml") unless defined? CONFIG

get "/" do
  erb :index
end

client = OAuth2::Client.new(
  CONFIG['clientid'], CONFIG['secret'],
  :site => "https://accounts.google.com",
  :token_url => "/o/oauth2/token",
  :authorize_url => "/o/oauth2/auth")

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
  uploadedFile = 'uploads/' + params['file'][:filename]
  if File.extname(uploadedFile) == '.psd'
    File.open(uploadedFile, "w") do |f|
      f.write(params['file'][:tempfile].read)
      psd = PsdFile.new(f)
      spreadsheet = SpreadSheet.new(session[:drive], params['file'][:filename], psd.rows)
      FileUtils.rm_rf(Dir.glob('uploads/*'))      
      return spreadsheet.sheet.human_url
    end
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