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
      unless File.exists? rc_path
        if File.exists? LOCAL_FILE
          if agree("Move existing rc: #{LOCAL_FILE}")
            File.rename LOCAL_FILE, rc_path
            link_rc
          else
            link_rc reverse: true
          end
        elsif agree('Create irbrc')
          create_rc
          link_rc
        end
      end

      load rc_path if File.exists? rc_path
      # eval(File.read(rc_path))
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
        fh.write "# IRBRC for #{parse_repo[:repo]}\n"
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
