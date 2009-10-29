require 'bookify'

file = ARGV.shift||'book.pdf'


puts Bookify.number_of_pages(:file => file)
puts Bookify.number_of_pages(:pdf => IO.read(file))
