class PusherStub
  # Mehtod missing to ignore any method calls
  def self.method_missing(*args)
    # Do nothing
  end

  # Respond to any method calls
  def self.respond_to_missing?(*args)
    true
  end
end