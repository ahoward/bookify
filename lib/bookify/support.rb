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

  def config_for(arg)
    case arg
      when Hash
        Bookify.normalized_hash(arg)
      when IO, StringIO
        Bookify.normalized_hash(YAML.load(arg.read))
      else
        Bookify.normalized_hash(YAML.load(IO.read(arg.to_s)))
    end
  end

  def prince
    @prince ||= (
      status, stdout, stderr = systemu('which prince')
      raise "no prince binary in PATH=#{ ENV['PATH'] }" unless status==0
      stdout.strip
    )
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
