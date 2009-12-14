module Bookify
  class Book
    include Render

    attr_accessor 'layout'
    attr_accessor 'style'
    attr_accessor 'helper'
    attr_accessor 'config'

    attr_accessor 'chapters'

    def initialize(*args)
      args, options = Bookify.args_for(args)

      @layout = (options[:layout] || :default).to_s
      @layout = Bookify.libdir('layouts', @layout) unless(@layout[0,1] == '/')
      raise("no layout #{ @layout.inspect }") unless test(?d, @layout)

      @style = options[:style]
      @style ||= File.join(@layout, "style.css")
      raise("no style #{ @style.inspect }") unless test(?e, @style) if @style

      @helper = build_helper

      config = options[:config]
      raise("no config") unless config

      configure!(config)
      extend!
    end

    def configure!(config)
      @config = Bookify.config_for(config)
      @chapters = []
      @config[:book][:chapters].each_with_index do |hash, index|
        chapter = Chapter.new(book, hash.update(:index => index))
        @chapters.push(chapter)
      end
    end

    def extend!
      extend(book.helper)
    end

    def to_html(*args)
      template = File.join(layout, "book.html.erb")
      template = Template.read(template)
      html = template.expand(book)

      html
    end

    def to_pdf(*args, &block)
      options = Bookify.options_for(args)
      filename = options.delete(:filename) || 'book.pdf'
      args.push(options)

      pdf = nil

      html = to_html(*args)

      command = "#{ Bookify.prince } --style=#{ @style.inspect } - -o -"
      status, stdout, stderr = systemu(command, :stdin => html)
      unless status==0
        STDERR.puts(stderr)
        abort "command(#{ command.inspect }) failed with status(#{ status.inspect })"
      end

      pdf = Blob.for(stdout, :filename => filename)

      command = "#{ Bookify.pdftk } - dump_data"
      status, stdout, stderr = systemu(command, :stdin => pdf)
      pdf.number_of_pages = Bookify.number_of_pages(:pdf => pdf)

      pdf
    end

    def build_helper
      @helper ||= Module.new{ include Helper }

      glob = File.join(book.layout, '*')
      custom_helpers = Dir[glob].select{|entry| entry =~ /helper.*\.rb/}.sort

      custom_helpers.each do |custom_helper|
        namespace = Module.new
        src = IO.read(custom_helper)
        before = namespace.constants
        namespace.module_eval(src)
        after = namespace.constants
        modules = (after - before).map{|constant| namespace.const_get(constant)}
        modules.each{|helper| @helper.module_eval{ include(helper) }}
      end

      @helper
    end

    def book
      self
    end
  end
end
