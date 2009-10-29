module Bookify
  class Template < ERB
    attr_accessor 'path'

    def Template.for(*args, &block)
      new(*args, &block)
    end

    def Template.read(pathname)
      template = Template.for(IO.read(pathname.to_s))
    ensure
      template.path = pathname.to_s if template
    end

    def initialize(*args, &block)
      options = Bookify.normalized_hash(args.last.is_a?(Hash) ? args.pop : {})
      @context = options[:context] || options[:object]
      string = (args.shift || block.call)
      #super(Bookify.unindent(string), safe_mode=nil, trim_mode='%')
      super(Bookify.unindent(string), safe_mode=nil, trim_mode='-%')
    end

    def expand(context = nil, &block)
      context ||= block.binding if block
      context ||= @context
      context ||= Object.new
      #raise ArgumentError, 'no context' unless context
      context = context.instance_eval('binding') unless context.respond_to?('binding')
      block.call(self) if block
      result(context)
    end

    class Xml < Template
      Declaration = '<?xml version="1.0" encoding="UTF-8"?>' unless defined?(Declaration)

      def initialize(string = '', options = {}, &block)
        options = Bookify.normalized_hash(options)

        declaration = options[:declaration]
        case declaration
          when TrueClass, FalseClass, NilClass
            declaration = Declaration if declaration
          else
            declaration = declaration.to_s
        end
        string = "#{ declaration }\n#{ Bookify.unindent(string) }" if declaration

        super(string, options, &block)
      end
    end

    def Template.xml(*args, &block)
      (args.empty? and block.nil?) ? Xml : Xml.for(*args, &block)
    end
  end
end
