require 'bookify'

template =
  Bookify::Template.xml(
    <<-__

      <size>
        <%= size %>
      </size>

      <elements>
        <% each do |element| %>
        <element> <%= element %> </element>
        <% end %>
      </elements>

    __
  )

puts template.expand(array = [])
puts template.expand(array = [42])
