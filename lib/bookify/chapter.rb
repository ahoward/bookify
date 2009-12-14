module Bookify
  class Chapter
    include Render

    attr_accessor 'book'
    attr_accessor 'config'

    attr_accessor 'title'
    attr_accessor 'start_date'
    attr_accessor 'end_date'
    attr_accessor 'sections'
    attr_accessor 'index'

    def initialize(book, config = {})
      @book = book
      configure!(config)
      extend!
    end

    def dates
      [start_date, end_date].compact
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
      @title = nil
      @start_date = nil
      @end_date = nil
      @sections = []

      @index = Integer(config[:index]) if config.has_key?(:index)
      @title = String(config[:title]) if config.has_key?(:title)

      @start_date = Date.parse(@start_date.to_s) if @start_date
      @end_date = Date.parse(@end_date.to_s) if @end_date

      (config[:sections] || []).each_with_index do |section_config, index|
        section = Section.new(chapter, section_config)
        section.index = index
        section.extend(book.helper)
        @sections.push(section)
      end
    end

    def extend!
      extend(book.helper)
    end

    def chapter
      self
    end
  end
end
