class Loop
  attr_accessor :file, :bars, :offset
  def self.from_sample s
    l = Loop.new
    l.file = s.file
    l.bars = s.bars
    l.offset = 0
    l
  end
  def delete
    metadata = @file.sub "wav","meta"
    del_dir = File.join(File.dirname(@file),"delete")
    puts `trash "#{metadata}"`
    puts `trash "#{@file}"`
  end
end

