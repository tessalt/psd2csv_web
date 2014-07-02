require "google_drive"

class SpreadSheet

  attr_reader :sheet, :ws

  def initialize(session, filename, rows)
    @session = session
    @filename = filename
    @rows = rows
    setup()
    build()    
  end

  protected

  def setup
    @sheet = @session.create_spreadsheet(@filename)
    @ws = sheet.worksheets[0]
    @ws[1,1] = "index"
    @ws[1,2] = "layer text"
  end

  def build
    @rows.each_with_index do |row, index|
      text = row[:text].gsub(/[[:cntrl:]]/, '')       
      @ws[index+2, 1] = row[:index]
      @ws[index+2, 2] = text
    end
    @ws.save
  end

end