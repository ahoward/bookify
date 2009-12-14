module Bookify
  class Section
    include Render

    attr_accessor 'config'

    attr_accessor 'chapter'
    attr_accessor 'index'
    attr_accessor 'type'
    attr_accessor 'title'
    attr_accessor 'date'
    attr_accessor 'content'
    attr_accessor 'images'
    attr_accessor 'split'

    def initialize(chapter, config = {})
      @chapter = chapter
      configure!(config)
      extend!
    end

    def dates
      [date].compact
    end

    def extend!
      extend(book.helper)
    end

    def book
      chapter.book
    end

    def helper
      book.helper
    end

    def layout
      book.layout
    end

    def style
      book.style
    end

    def configure!(config = {})
      @config = Bookify.config_for(config)
      @type = nil
      @title = nil
      @dates = []
      @content = nil
      @images = []

      @index = Integer(config[:index]) if config.has_key?(:index)
      @type = String(config[:type]) if config.has_key?(:type)
      @title = String(config[:title]) if config.has_key?(:title)
      @content = String(config[:content]) if config.has_key?(:content)
      @split = String(config[:split]) if config.has_key?(:split)

      Array(config[:dates]).each do |date|
        @dates.push(Date.parse(date.to_s))
      end

      Array(config[:images]).each do |image|
        @images.push(image)
      end
    end

    def section
      self
    end
  end
end
