module Bookify
  class Blob < String
    attr_accessor 'pathname'
    alias_method 'filename', 'pathname'
    alias_method 'filename=', 'pathname='
    attr_accessor 'content_type'
    alias_method 'type', 'content_type'
    alias_method 'type=', 'content_type='

    def Blob.for(*args)
      args, options = Bookify.args_for(args)

      content = args.shift || options[:content] 
      pathname = args.shift || options[:pathname] || options[:filename]

      if content.respond_to?(:read)
        %w( original_filename filename pathname ).each do |msg|
          if content.respond_to?(msg)
            pathname = content.send(msg)
            content = content.read
            break
          end
        end
      end

      raise ArgumentError, content.class.name unless pathname and content

      blob = new(content, :pathname => pathname)
      %w( pathname filename content_type contenttype type ).each do |key|
        if options.has_key?(key)
          setter, value = "#{ key }=", options[key]
          blob.send(setter, value) if options.has_key?(key)
        end
      end
      blob
    end

    def initialize(*args)
      args, options = Bookify.args_for(args)
      self.pathname = options[:pathname]||options[:filename]
      self.content_type = options[:content_type]||options[:contenttype]||options[:type]||content_type_for(self.pathname)
      super(args.join)
    end

    def to_s() self end
    alias_method 'data', 'to_s'
    alias_method 'contents', 'to_s'

    def content_type_for(pathname)
      MIME::Types.type_for(pathname.to_s).first.to_s
    end

    def inspect
      "#{ self.class.name }(pathname=#{ pathname.inspect }, contents=#{ ellipsis.inspect })"
    end

    def ellipsis
      size>42 ? self[0,42]+'...' : self
    end
  end
end
