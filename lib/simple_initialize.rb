module SimpleInitialize
  def initialize_with(*fields)
    attr_reader(*fields)

    define_method :initialize do |*values|
      raise ArgumentError, "wrong number of arguments (#{values.count} for #{fields.count})" if values.count != fields.count
      fields.zip(values).each do |field_name, value|
        instance_variable_set "@#{field_name}", value
      end
    end
  end
end

Class.send :include, SimpleInitialize
