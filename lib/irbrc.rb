require 'fileutils'


module Irbrc
  VERSION = '0.0.2'
  BASE_DIR = [
    Dir.home,
    '.irb/rc',
  ].join File::SEPARATOR


  class << self


    def load_rc
      if rc_path
        init unless File.exists? rc_path

        if File.exists? rc_path and rc_path != global_rc
          load rc_path
        end
      end
    end


    def init
      if File.exists? local_rc
        if rc_path == File.realpath(local_rc)
          # already linked, no-op
        elsif agree("Move existing rc: #{local_rc}")
          FileUtils.mkpath File.dirname rc_path
          File.rename local_rc, rc_path
          link_rc
        else
          link_rc reverse: true
        end
      elsif agree('Create irbrc')
        create_rc unless File.exists? rc_path
        link_rc
      end

      init_global_rc
      git_ignore if is_git?

      nil
    end


    # add auto-load to ~/.irbrc
    def init_global_rc
      require_cmd = "require 'irbrc'"

      add_required = if File.exists? global_rc
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


    def git_ignore
      ignore_path = [
        project_root,
        '.git',
        'info',
        'exclude'
      ].join File::SEPARATOR
      add_required = if File.exists? ignore_path
        msg = "Add .irbrc to #{ignore_path}"
        File.read(ignore_path) !~ /\W\.irbrc\W/ and agree(msg)
      else
        add_required = true
      end

      if add_required
        File.open(ignore_path, 'a') do |fh|
          fh.write "\n.irbrc\n"
        end
      end
    end


    def localize
      if File.exists? local_rc
        if File.realpath(local_rc) == rc_path
          unlink local_rc
        else
          unlink local_rc if agree "Overwrite local rc: #{local_rc}"
        end
      end

      File.rename rc_path, local_rc unless File.exists? local_rc
    end


    def remove_rc
      unlink rc_path, local_rc
    end


    def create_rc opts = {}
      unlink rc_path if opts[:force]

      if File.exists? rc_path
        raise Exception.new "rc file already exists: #{rc_path}"
      end

      FileUtils.mkpath File.dirname rc_path
      msg = if is_git?
        repo = parse_repo
        "# IRBRC for #{parse_repo[:source]}:#{repo[:repo]}\n"
      else
        "# IRBRC"
      end


      File.open(rc_path, 'w') do |fh|
        fh.write "#{msg}\n\n"
      end

      nil
    end


    def link_rc opts = {}
      if opts[:reverse]
        unlink rc_path if opts[:force]
        File.symlink File.realpath(local_rc), rc_path
      else
        if realpath(local_rc) != realpath(rc_path)
          unlink local_rc if opts[:force]
          File.symlink rc_path, local_rc
        end
      end

      nil
    end


    def rc_path
      if is_git?
        repo = parse_repo
        [
          BASE_DIR,
          repo[:source],
          repo[:repo].gsub(/#{File::SEPARATOR}/, '.') + '.rc',
        ].join File::SEPARATOR
      else
        local_rc
      end
    end


    def parse_repo str = nil
      str = git_cmd "remote -v" unless str

      repos = str.split("\n").map(&:split).map do |line|
        next unless line.first.match /^origin/

        source, repo = line[1].split ':'
        source.sub! /^.*@/, ''
        source.sub! /\.(com|org)$/, ''

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
        project_root,
        '.irbrc'
      ].join File::SEPARATOR
    end


    def global_rc
      [ Dir.home, '.irbrc' ].join File::SEPARATOR
    end


    def project_root
      git_cmd("rev-parse --show-toplevel") || Dir.pwd
    end


    def agree msg, opts = {}
      # ask yes or no question and return true/false
      # optional 'default' arg

      default = if opts.has_key? :default
        opts[:default] ? 'y' : 'n'
      else
        ''
      end

      loop do
        puts "#{msg.chomp '?'}?  %s" % '[y/n]'.sub(default, default.upcase)
        res = gets.strip.downcase
        res = default if res.empty?
        if ['y', 'yes', 'n', 'no'].include? res
          return ['y', 'yes'].include? res
        else
          puts "\ninvalid response\n\n"
        end
      end
    end


    def unlink *paths
      paths.select do |path|
        1 == File.unlink(path) if File.exists? path or File.symlink? path
      end
    end


    def realpath path
      File.realpath path if File.exists? path
    end


    @@is_git = {}
    def is_git? path = Dir.pwd
      is_git = @@is_git[path]

      if is_git.nil?
        # not cached yet
        dir = `git rev-parse --show-toplevel 2>/dev/null`.chomp
        is_git = !dir.empty?

        dir = is_git ? dir : path
        @@is_git[dir] = is_git
      end

      is_git
    end


    def git_cmd cmd
      `git #{cmd} 2>/dev/null`.chomp if is_git?
    end


  end
end


# define global function for convenience
define_singleton_method(:load_rc) { Irbrc.load_rc }
