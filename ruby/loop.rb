class Loop
  attr_accessor :file, :bars, :offset
  def self.from_sample s
    l = Loop.new
    l.file = s.file
    l.bars = s.bars
    l.offset = 0
    l
  end
end

