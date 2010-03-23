class REXML::Element
  # Helper to create xml docs with a nested syntax.
  def with_element(*args)
    e = add_element(*args)
    yield e if block_given?
  end
end