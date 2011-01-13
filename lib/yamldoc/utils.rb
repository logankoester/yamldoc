class String
  # Strip any # characters and leading whitespace
  # 
  # Returns an lstripped String
  def uncomment
    return self.partition(/\s*#\s+/).last
  end
end
