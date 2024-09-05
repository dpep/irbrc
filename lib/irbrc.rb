require 'fileutils'


module Irbrc
  extend self

  VERSION = '0.0.2'
  BASE_DIR = [
    Dir.home,
    '.irb/rc',
  ].join File::SEPARATOR


  def load_rc
    if File.exists?(local_rc) && local_rc != global_rc
      load local_rc
    end
  end


  # set up or fix this project's rc file and symlink
  def init
    if File.symlink?(local_rc)
      if ! File.exists?(local_rc)
        # clean up bad symlink
        unlink(local_rc)
      end
    elsif File.exists?(local_rc)
      if remote_rc and agree("Move local rc: mv #{local_rc} #{remote_rc}")
        FileUtils.mkpath(File.dirname(remote_rc))
        File.rename(local_rc, remote_rc)
      end
    elsif ! realpath(remote_rc) && agree('Create irbrc', default: true)
      # create new rc file
      create_rc
    end

    if ! File.exists?(local_rc) && realpath(remote_rc)
      # symlink remote rc
      File.symlink(remote_rc, local_rc)
    end

    init_global_rc
    git_ignore if git_env?

    nil
  end


  def create_rc
    path = remote_rc || local_rc

    if File.exists?(path)
      raise Exception.new "rc file already exists: #{path}"
    end

    if remote_rc
      FileUtils.mkpath(File.dirname(remote_rc))
    end

    msg = if repo = parse_repo
      "# IRBRC for #{parse_repo[:source]}:#{repo[:repo]}\n"
    else
      "# IRBRC"
    end

    File.open(path, 'w') do |fh|
      fh.write "#{msg}\n\n"
    end
  end


  # Ensure ~/.irbrc loads Irbrc upon irb start.
  def init_global_rc
    require_cmd = "require 'irbrc'"

    add_required = if File.exists?(global_rc)
      add_msg = "Add `#{require_cmd}` to #{global_rc}"
      File.read(global_rc) !~ /\W#{require_cmd}\W/ and agree(add_msg)
    else
      true
    end

    if add_required
      File.open(global_rc, 'a') do |fh|
        fh.write "\n"
        fh.write "# load per project .irbrc\n"
        fh.write "#{require_cmd}\n"
        fh.write "load_rc\n\n"
      end
    end
  end


  # Add rc file to git ignore.
  def git_ignore(filename = '.irbrc')
    return if system("git check-ignore -q #{filename}")

    ignore_path = [
      project_root,
      '.git',
      'info',
      'exclude'
    ].join File::SEPARATOR

    # return unless File.exists?(ignore_path)

    if agree("Add #{filename} to #{ignore_path}", default: true)
      File.open(ignore_path, 'a') do |fh|
        fh.write "\n#{filename}\n"
      end
    end
  end


  def remote_rc
    if repo = parse_repo
      name = repo[:repo].gsub(/\.git$/, '').gsub(/#{File::SEPARATOR}/, '.')

      [
        BASE_DIR,
        "#{repo[:source]}.#{name}.rb",
      ].join File::SEPARATOR
    end
  end


  def parse_repo(str = nil)
    str = git_cmd("remote -v") unless str
    return unless str

    repos = str.split("\n").map(&:split).map do |line|
      next unless line.first == "origin"
      next unless line.last == "(fetch)"

      source, repo = line[1].split ':'
      source.sub!(/^.*@/, '')
      source.sub!(/\.(com|org)$/, '')

      {
        source: source,
        repo: repo,
      }
    end.compact.uniq

    if repos.count != 1
      raise Exception.new "parse error: #{str}"
    end

    repos.first
  end


  def local_rc
    [
      project_root || Dir.pwd,
      '.irbrc'
    ].join File::SEPARATOR
  end


  def global_rc
    [ Dir.home, '.irbrc' ].join File::SEPARATOR
  end


  def project_root
      git_cmd("rev-parse --show-toplevel")
  end


  def agree(msg, **opts)
    # ask yes or no question and return true/false
    # optional 'default' arg

    default = if opts.has_key?(:default)
      opts[:default] ? 'y' : 'n'
    else
      ''
    end

    loop do
      puts "#{msg.chomp('?')}?  %s" % '[y/n]'.sub(default, default.upcase)
      res = gets.strip.downcase
      res = default if res.empty?
      if ['y', 'yes', 'n', 'no'].include? res
        return ['y', 'yes'].include? res
      else
        puts "\ninvalid response\n\n"
      end
    end
  end


  def unlink(*paths)
    paths.select do |path|
      1 == File.unlink(path) if File.exists?(path) || File.symlink?(path)
    end
  end


  def realpath(path)
    File.realpath(path) if path and File.exists?(path)
  end


  def git_env?
    !! git_cmd('status --short')
  end


  def git_cmd cmd
    res = `git #{cmd} 2>/dev/null`.chomp
    res.empty? ? nil : res
  end


  # remove rc file
  def remove
    if agree("remove rc file")
      unlink(local_rc, remote_rc)
    end
  end


  # use local rc file instead of symlink
  def localize
    if File.symlink?(local_rc)
      unlink(local_rc)
    end

    if File.exists?(local_rc)
      unlink(local_rc) if agree("Overwrite local rc: #{local_rc}")
    end

    File.rename(remote_rc, local_rc) unless File.exists?(local_rc)
  end
end


# define global function for convenience
define_singleton_method(:load_rc) { Irbrc.load_rc }
