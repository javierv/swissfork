# ArrayExchange provides an easy way to exchange two
# elements in an Array.
#
# It adds an instance method to Array (#exchange) which
# receives two elements and swaps their position.
#
module ArrayExchange
  # Returns a new array with two elements exchanging their position.
  def exchange(first_element, second_element)
    first_index, second_index = index(first_element), index(second_element)

    dup.tap do |array|
      array[first_index], array[second_index] = second_element, first_element
    end
  end
end

Array.send :include, ArrayExchange
