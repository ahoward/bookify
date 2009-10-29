module Bookify
  class Book
    attr_accessor 'config'
    attr_accessor 'chapters'

    def initialize(config = {})
      @rendering = false
      @layout = nil
      @style = nil
      configure(config)
    end

    def configure(config)
      @config = Bookify.config_for(config)
      @chapters = []
      @config[:book][:chapters].each_with_index do |hash, index|
        chapter = Chapter.new(hash.update(:index => index))
        @chapters.push(chapter)
      end
    end

    def to_html(*args)
      rendering(*args) do
        template = File.join(@layout, "book.html.erb")
        @template = Template.read(template)
        @template.expand(book)
      end
    end

    def rendering(*args, &block)
      return(block.call) if @rendering

      begin
        @rendering = true
        args, options = Bookify.args_for(args)

        @layout = (options[:layout] || :default).to_s
        @layout = Bookify.libdir('layouts', @layout) unless(@layout[0,1] == '/')
        raise "no layout #{ @layout.inspect }" unless test(?d, @layout)

        @style = options[:style]
        @style ||= File.join(@layout, "style.css")
        if @style
          raise "no style #{ @style.inspect }" unless test(?e, @style)
        end

        Dir.chdir(@layout) do
          block.call
        end
      ensure
        @layout = @style = nil
        @rendering = false
      end
    end

    def to_pdf(*args, &block)
      options = Bookify.options_for(args)
      filename = options.delete(:filename) || 'book.pdf'
      args.push(options)

      pdf = nil

      rendering(*args) do
        html = to_html(*args)

        command = "#{ Bookify.prince } - -o -"
        status, stdout, stderr = systemu(command, :stdin => html)
        raise "command(#{ command.inspect }) failed with status(#{ status.inspect })" unless status==0

        pdf = Blob.for(stdout, :filename => filename)

        command = "#{ Bookify.pdftk } - dump_data"
        status, stdout, stderr = systemu(command, :stdin => pdf)
        pdf.number_of_pages = Bookify.number_of_pages(:pdf => pdf)
      end

      pdf
    end

    def render(*args)
      args, options = Bookify.args_for(args)

      args.each do |arg|
        case arg
          when Section
            options[:section] = arg
        end
      end

      template = options[:template]

      if options.has_key?(:section)
        section = options[:section]
        basename = ['section', section.type].compact.join('-')
        template ||= basename
        context = section
      end

      template = template.to_s
      template = File.join(@layout, template) unless template[0,1]=='/'
      template += '.html.erb' unless(template.split('.').size > 1)

      template = Template.read(template)
      template.expand(context)
    end
    
    def h(*args, &block)
      args.push(block.call.to_s) if block
      CGI.escape(args.join)
    end

    def book
      self
    end

    class Chapter
      attr_accessor 'config'

      attr_accessor 'title'
      attr_accessor 'dates'
      attr_accessor 'sections'
      attr_accessor 'index'

      def initialize(config = {})
        configure(config)
      end

      def configure(config = {})
        @config = Bookify.config_for(config)
        @title = nil
        @dates = []
        @sections = []

        @index = Integer(config[:index]) if config.has_key?(:index)
        @title = String(config[:title]) if config.has_key?(:title)

        (config[:dates] || []).each do |date|
          @dates.push(Date.parse(date.to_s))
        end
        (config[:sections] || []).each_with_index do |section_config, index|
          section = Section.new(chapter, section_config)
          section.index = index
          @sections.push(section)
        end
      end

      def chapter
        self
      end
    end

    class Section
      attr_accessor 'config'

      attr_accessor 'chapter'
      attr_accessor 'index'
      attr_accessor 'type'
      attr_accessor 'title'
      attr_accessor 'dates'
      attr_accessor 'content'

      def initialize(chapter, config = {})
        @chapter = chapter
        configure(config)
      end

      def configure(config = {})
        @config = Bookify.config_for(config)
        @type = nil
        @title = nil
        @dates = []
        @content = nil

        @index = Integer(config[:index]) if config.has_key?(:index)
        @type = String(config[:type]) if config.has_key?(:type)
        @title = String(config[:title]) if config.has_key?(:title)
        @content = String(config[:content]) if config.has_key?(:content)

        (config[:dates] || []).each do |date|
          @dates.push(Date.parse(date.to_s))
        end
      end

      def section
        self
      end
    end
  end
end
