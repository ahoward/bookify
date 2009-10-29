module Bookify
  class Book
    attr_accessor 'config'
    attr_accessor 'chapters'

    def initialize(config = {})
      configure(config)
    end

    def h(*args, &block)
      args.push(block.call.to_s) if block
      CGI.escape(args.join)
    end

    def configure(config)
      @config = Bookify.config_for(config)
      @chapters = []
      @config[:book][:chapters].each_with_index do |hash, index|
        chapter = Chapter.new(hash.update(:index => index))
        @chapters.push(chapter)
      end
    end

    def expand(*args)
      args, options = Bookify.args_for(args)
      options = Bookify.hash_for(options.is_a?(Hash) ? options : {:layout => options})

      options[:layout] ||= :default
      layout = options[:layout].to_s

      @layout_dir = layout
      unless @layout_dir[0,1] == '/'
        @layout_dir = Bookify.libdir('layouts', @layout_dir)
      end
      @layout = "#{ @layout_dir }/layout.html.erb"

      template = Template.read(@layout)
      template.expand(book)

    ensure
      @layout_dir = @layout = nil
    end

    alias_method 'to_html', 'expand'

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
      template = File.join(@layout_dir, template) unless template[0,1]=='/'
      template += '.html.erb' unless(template.split('.').size > 1)

      template = Template.read(template)
      template.expand(context)
    end

    def to_pdf(*args, &block)
      args, options = Bookify.args_for(args)
      options[:filename] ||= 'book.pdf'
      html = expand(*[args, options])
      command = "#{ Bookify.prince } - -o -"
      status, stdout, stderr = systemu(command, :stdin => html)
      raise "command(#{ command.inspect }) failed with status(#{ status.inspect })" unless status==0
      Blob.for(stdout, options)
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
        (config[:sections] || []).each do |section_config|
          @sections.push(Section.new(section_config))
        end
      end
    end

    class Section
      attr_accessor 'config'

      attr_accessor 'index'
      attr_accessor 'type'
      attr_accessor 'title'
      attr_accessor 'dates'
      attr_accessor 'content'

      def initialize(config = {})
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
