module Bookify
  class Book
    attr_accessor 'config'

    def initialize(config = {})
      @config = Bookify.config_for(config)
      configure(@config)
    end

    def h(*args, &block)
      args.push(block.call.to_s) if block
      CGI.escape(args.join)
    end

    def configure(config)
    end

    def expand(*args)
      args, options = Bookify.args_for(args)
      options = Bookify.hash_for(options.is_a?(Hash) ? options : {:template => options})

      options[:template] ||= :default
      template = options[:template].to_s

      unless test(?e, template)
        has_extension = template.split('.').size > 1
        template = "#{ template }.html.erb" unless has_extension
        template = Bookify.libdir(:templates, template)
      end

      template = Template.read(template)
      template.expand(book)
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
  end
end
