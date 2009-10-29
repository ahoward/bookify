module Bookify
  def normalized_hash(hash = {})
    HashWithIndifferentAccess.new.update(hash)
  end
  alias_method 'normalized_hash_for', 'normalized_hash'
  alias_method 'hash_for', 'normalized_hash'

  def hostname
    @hostname ||= (Socket.gethostname rescue 'localhost')
  end

  def ppid
    @ppid ||= Process.ppid
  end

  def pid
    @pid ||= Process.pid
  end

  def tmpdir(&block)
    parts = [
      'bookify',
      hostname,
      ppid,
      pid,
      Thread.current.object_id.abs,
      Kernel.rand
    ]
    tmpdir = File.join(Dir.tmpdir, parts.join('-'))
    begin
      FileUtils.mkdir_p(tmpdir)
      Dir.chdir(tmpdir, &block)
    ensure
      FileUtils.rm_rf(tmpdir)
    end
  end

  def config_for(config)
    case config
      when NilClass
      raise
        Bookify.normalized_hash()
      when Hash
        Bookify.normalized_hash(config)
      when IO, StringIO
        Bookify.normalized_hash(YAML.load(config.read))
      else
        Bookify.normalized_hash(YAML.load(IO.read(config.to_s)))
    end
  end

  def prince
    @prince ||= (
      status, stdout, stderr = systemu('which prince')
      raise "no prince binary in PATH=#{ ENV['PATH'] }" unless status==0
      stdout.strip
    )
  end

  def pdftk
    @pdftk ||= (
      status, stdout, stderr = systemu('which pdftk')
      raise "no pdftk binary in PATH=#{ ENV['PATH'] }" unless status==0
      stdout.strip
    )
  end

  def identify
    @identify ||= (
      status, stdout, stderr = systemu('which identify')
      raise "no identify binary in PATH=#{ ENV['PATH'] }" unless status==0
      stdout.strip
    )
  end

  def number_of_pages(options = {})
    options = Bookify.hash_for(options)

    stdin = options[:pdf] if options.has_key?(:pdf)
    stdin = options[:stdin] if options.has_key?(:stdin)
    stdin = IO.read(options[:path]) if options.has_key?(:path)
    stdin = IO.read(options[:file]) if options.has_key?(:file)

    number_of_pages = nil

    if number_of_pages.nil?
      begin
        command = "#{ pdftk } - dump_data"
        status, stdout, stderr = systemu(command, :stdin => stdin)
        raise "command(#{ command.inspect }) failed with (#{ status.inspect })" unless status==0
        line = stdout.split(%r/\n/).grep(/NumberOfPages:/).first
        number_of_pages = Integer(line[%r/\s*\d+\s*$/])
      rescue
        nil
      end
    end

    if number_of_pages.nil?
      begin
        command = "#{ identify } -"
        status, stdout, stderr = systemu(command, :stdin => stdin)
        raise "command(#{ command.inspect }) failed with (#{ status.inspect })" unless status==0
        line = stdout.split(%r/\n/).last
        token = line.strip.split(%r/\s+/).first
        index = token[%r/\[\s*\d+\s*\]\s*$/]
        if index
          number_of_pages = Integer(index[%r/\d+/])
        else
          number_of_pages = 1
        end
      rescue
        nil
      end
    end

    raise "could not determine number_of_pages" if number_of_pages.nil?
    number_of_pages
  end

  def unindent!(s)
    indent = nil
    s.each do |line|
      next if line =~ %r/^\s*$/
      indent = line[%r/^\s*/] and break
    end
    s.gsub! %r/^#{ indent }/, "" if indent
    s
  end

  def unindent(s)
    unindent! "#{ s }"
  end

  def indent!(s, n = 2)
    n = Integer n
    margin = ' ' * n
    unindent! s
    s.gsub! %r/^/, margin
    s
  end

  def indent(s, n = 2)
    indent!(s.to_s.dup, n)
  end

  def args_for(args)
    options = Bookify.hash_for(args.last.is_a?(Hash) ? args.pop : {})
    [args, options]
  end
end
