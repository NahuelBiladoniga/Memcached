require 'optparse'
require_relative 'server'

class ServerParser
  def self.parse(args)
    @options = {:address => "localhost",:port => 11211,:time_crawler => 30}
    opts = OptionParser.new do |opts|
      opts.banner = "MemCached Server CLI"

      opts.on('-a', '--address <address>', 'Listen on TCP address <num>, the default is localhost.') do |port|
        @options[:port] = port
      end

      opts.on('-p', '--port <num>', 'Listen on TCP port <num>, the default is port 11211.') do |address|
        @options[:address] = address
      end

      opts.on('-tc',
                  '--time_crawler <num>',
                  'Time in seconds for the crawler to delete expired keys time_crawler <num>, the default value is 30.') do |time_crawler|
        @options[:time_crawler] = time_crawler
      end

      opts.on('-h', '--help', OptionParser::OctalInteger, 'Help command') do |help|
        puts opts
        exit
      end
    end

    opts.parse(args)
    server = Server.new(@options[:address],@options[:port],@options[:time_crawler],true)
    server.start_server

  end
end

ServerParser.parse(ARGV)
