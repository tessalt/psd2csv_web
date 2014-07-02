class PsdFile

  attr_reader :file, :rows

  def initialize(file) 
    @file = PSD.new(file, parse_layer_images: true)
    @rows = Array.new
    extract_rows()
    sort_rows()
  end

  protected

  def extract_rows 
    @file.tree.descendant_layers.each do |layer|
      unless layer.text.nil?
        matches = /\*\[([a-zA-Z]\d*)/.match(layer.name)
        if matches
          row = Hash.new
          row[:index] = matches[1]
          row[:text] = layer.text[:value]
          @rows.push(row)
        end
      end
    end
  end

  def sort_rows
    @rows.sort! do |a, b|
      a[:index].upcase <=> b[:index].upcase
    end
  end

end
