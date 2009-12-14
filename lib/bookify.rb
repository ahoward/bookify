require 'socket'
require 'tmpdir'
require 'fileutils'
require 'erb'
require 'cgi'
require 'date'

begin
  require 'rubygems'
rescue LoadError
  nil
end

require 'tagz' # ???
require 'systemu'
require 'orderedhash'
require 'mime/types'

module Bookify
  Version = '0.0.1' unless defined?(Version)

  def version
    Bookify::Version
  end

  def libdir(*args, &block)
    @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
    args.empty? ? @libdir : File.join(@libdir, *args.map{|arg| arg.to_s})
  ensure
    if block
      begin
        $LOAD_PATH.unshift(@libdir)
        block.call()
      ensure
        $LOAD_PATH.shift()
      end
    end
  end

  extend self
end



Bookify.libdir do
  load 'errors.rb'
  load 'hash_with_indifferent_access.rb'
  load 'support.rb'
  load 'blob.rb'
  load 'template.rb'
  load 'render.rb'
  load 'helper.rb'
  load 'book.rb'
  load 'chapter.rb'
  load 'section.rb'

  Bookify.autoload(:Fake, Bookify.libdir('fake.rb'))
end





def Bookify(config = {}, *args, &block)
  Bookify::Book.new(config).to_pdf(*args, &block)
end
