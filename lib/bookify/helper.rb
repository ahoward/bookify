module Bookify
  module Helper
    def h(*args, &block)
      args.push(block.call.to_s) if block
      CGI.escapeHTML(args.join)
    end

    def simple_format(text, options = {})
      content = text.to_s.
        gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
        gsub(/\n\n+/, "</p>\n\n<p>").           # 2+ newline  -> paragraph
        gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
      "<p>#{ content }</p>"
    end

    def clean_format(text, options = {})
      simple_format(h(text)).gsub(%r/([\ ]{2,})/){'&nbsp;' * $1.size}
    end
        
    def c(*args, &block)
      clean_format(*args, &block)
    end
  end
end
