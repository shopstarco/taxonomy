require 'bundler/setup'
Bundler.require
require 'active_support/core_ext/string'

class Taxonomy
  def initialize
    @file = ARGV[0]
    @file_output = ARGV[1]
    @rows = []
  end

  def execute
    readFile
    writeFile
  end

  def readFile
    File.open(@file).each_with_index do |row, index|
      next if index == 0
      analyse(row)
    end
  end

  def writeFile
    File.open(@file_output, "w") do |f|
      @rows.each do |row|
        f.puts(row)
        f.write "\n"
      end
    end
  end

  private
  # filter integer -
  # only get string: 505297 - Animals & Pet Supplies
  # get Animals & Pet Supplies
  def row_filter(row)
    row = row.strip.gsub(/\s+/, " ")
    row.split(" - ").last
  end

  def filter_special_symbol(row)
    row.gsub(/\&|\,|\'|\?|\~|\!|\@|\#|\$|\%|\^|\&|\*|\(|\)|\_|\+|\{|\}|\:|\`/, "")
  end

  def filter_special_name(row)
    return row.gsub(/\'/, "`") if row.include?("'")
    row
  end

  def analyse(row)
    row = row_filter(row)
    if row.include?(">")
      arr_row = row.split(">")
      @rows << analyse_sibling(row, arr_row)
    else
      row_tmp = filter_special_symbol(row)
      row = filter_special_name(row.squish)
      @rows << "#{wikify(row_tmp)} = Category.create(name: '#{row}')"
    end
  end

  def analyse_sibling(row, parent)
    tmp = []
    parent_name = ""
    parent.each_with_index do |item, index|
      item = filter_special_name(item.squish)
      item_tmp = filter_special_symbol(item)
      if index == 0
        parent_name = wikify(item_tmp)
        tmp << "#{parent_name} = Category.create(name: '#{item}')"
      else
        parent_child_name = wikify(item_tmp)
        tmp << "#{parent_child_name} = Category.create(name: '#{item}', parent: #{parent_name})"
        parent_name = parent_child_name
      end
    end
    tmp
  end

  # convert text to underscore
  # Some Text Here -> some_text_here
  def wikify(word)
    begin
      word = word.gsub(/^[a-z]|\s+[a-z]/) { |a| a.upcase }
      word = word.gsub(/\s/, '')
      word.underscore
    rescue => e
      puts e.inspect
      puts e.backtrace
    end
  end

end

taxonomy = Taxonomy.new
taxonomy.execute
