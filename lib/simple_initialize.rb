# SimpleInitialize provides an easy way to initialize an object.
#
# This method replaces the simple constructor when we take
# parameters and assign them to instance variables.
#
# Without SimpleInitialize:
#
# class Person
#   attr_reader :name, :gender
#
#   def initialize(name, gender)
#     @name = name
#     @gender = gender
#   end
# end
#
# With SimpleInitialize:
#
# class Person
#   initialize_with :name, :gender
# end
module SimpleInitialize
  def initialize_with(*fields)
    attr_reader(*fields)

    define_method :initialize do |*values|
      raise ArgumentError, "wrong number of arguments (#{values.size} for #{fields.size})" if values.size != fields.size
      fields.zip(values).each do |field_name, value|
        instance_variable_set "@#{field_name}", value
      end
    end
  end
end

Class.send :include, SimpleInitialize
