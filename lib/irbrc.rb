require 'fileutils'
require 'highline'


module Irbrc
  VERSION = '0.0.1'
  BASE_DIR = [
    Dir.home,
    '.irb/rc',
  ].join File::SEPARATOR
  LOCAL_FILE = '.irbrc'


  class << self

    def load_rc
      init unless File.exists? rc_path
      load rc_path if File.exists? rc_path
    end


    def init
      if File.exists? LOCAL_FILE
        if rc_path == File.realpath(LOCAL_FILE)
          # already linked, no-op
        elsif agree("Move existing rc: #{LOCAL_FILE}")
          File.rename LOCAL_FILE, rc_path
          link_rc
        else
          link_rc reverse: true
        end
      elsif agree('Create irbrc')
        create_rc
        link_rc
      end

      # add auto-load to ~/.irbrc
      global_rc = [ Dir.home, '.irbrc' ].join File::SEPARATOR
      require_cmd = "require 'irbrc'"

      add_require = if File.exists? global_rc
        add_msg = "Add `#{require_cmd}` to #{global_rc}"
        File.read(global_rc) !~ /\W#{require_cmd}\W/ and agree(add_msg)
      else
        true
      end

      if add_require
        File.open(global_rc, 'a') do |fh|
          fh.write "\n"
          fh.write "# `load_rc` to reload your project's local .irbrc\n"
          fh.write "#{require_cmd}\n\n"
        end
      end

      nil
    end


    def localize opts = {}
      if File.exists? LOCAL_FILE
        if opts[:force] or File.realpath(LOCAL_FILE) == rc_path
          unlink LOCAL_FILE
        else
          unlink LOCAL_FILE if agree "Remove local rc: #{LOCAL_FILE}"
        end
      end

      File.rename rc_path, LOCAL_FILE unless File.exists? LOCAL_FILE
    end


    def remove_rc opts = {}
      unlink rc_path, LOCAL_FILE
    end


    def create_rc opts = {}
      unlink rc_path if opts[:force]

      if File.exists? rc_path
        raise Exception.new "rc file already exists: #{rc_path}"
      end

      FileUtils.mkpath File.dirname rc_path
      File.open(rc_path, 'w') do |fh|
        repo = parse_repo
        fh.write "# IRBRC for #{parse_repo[:source]}:#{repo[:repo]}\n"
        fh.write "\n\n"
      end

      nil
    end


    def link_rc opts = {}
      if opts[:reverse]
        unlink rc_path if opts[:force]
        File.symlink File.realpath(LOCAL_FILE), rc_path
      else
        unlink LOCAL_FILE if opts[:force]
        File.symlink rc_path, LOCAL_FILE
      end

      nil
    end


    def rc_path
      repo = parse_repo

      [
        BASE_DIR,
        repo[:source],
        repo[:repo].sub(/#{File::SEPARATOR}/, '.') + '.rc',
      ].join File::SEPARATOR
    end


    def parse_repo str = nil
      str = `git remote -v` unless str

      repos = str.split("\n").map(&:split).map do |line|
        source, repo = line[1].split ':'
        source.sub! /^.*@/, ''
        source.sub! /\.(com|org)$/, ''

        {
          source: source,
          repo: repo,
        }
      end.uniq

      if repos.count != 1
        raise Error.new "parse error: #{str}"
      end

      repos.first
    end


    def agree msg
      HighLine.new.agree("#{msg}?  [Y/n]") do |q|
        yield q if block_given?
      end
    end


    def unlink *paths
      paths.select do |path|
        1 == File.unlink(path) if File.exists? path or File.symlink? path
      end
    end


  end
end


# define global function for convenience
define_singleton_method(:load_rc) { Irbrc.load_rc }
