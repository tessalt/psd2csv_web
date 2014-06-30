require 'rubygems'
require 'sinatra'
require 'psd'
require 'csv'
require 'json'
require 'oauth2'
require "google_drive"
require "yaml"

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
  puts params
  uploadedFile = 'uploads/' + params['file'][:filename]
  if File.extname(uploadedFile) == '.psd'
    File.open(uploadedFile, "w") do |f|
      f.write(params['file'][:tempfile].read)
      psd = PSD.new(f, parse_layer_images: true)
      csv_file = 'psd.csv'
      rows = Array.new

      psd.tree.descendant_layers.each do |layer|
        unless layer.text.nil?
          matches = /\*\[([a-zA-Z]\d*)/.match(layer.name)
          if matches
            row = Hash.new
            row[:index] = matches[1]
            row[:text] = layer.text[:value]
            rows.push(row)
          end
        end
      end

      sorted_rows = rows.sort do |a, b|
        a[:index].upcase <=> b[:index].upcase
      end

      sheet = session[:drive].create_spreadsheet(params['file'][:filename])
      ws = sheet.worksheets[0]

      ws[1,1] = "index"
      ws[1,2] = "layer text"

      sorted_rows.each_with_index do |row, index|
        text = row[:text].gsub(/[[:cntrl:]]/, '')       
        ws[index+2, 1] = row[:index]
        ws[index+2, 2] = text
      end

      FileUtils.rm_rf(Dir.glob('uploads/*'))

      ws.save

      return sheet.human_url

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