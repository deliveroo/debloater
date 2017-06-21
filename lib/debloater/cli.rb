require 'debloater/connection'
require 'debloater/engine'
require 'io/console'

module Debloater
  class CLI
    DEFAULTS = {
      connection: {
        host:     'localhost',
        port:     5432,
        user:     'postgres',
        password: nil,
        dbname:   nil,
      },
      engine: {
        confirm:    true,
        min_mb:     50,
        max_density: 0.75,
      },
      prompt_password: true,
    }

    def initialize(argv)
      @options = DEFAULTS.dup
      _parse(argv.dup, @options)
    end
    
    def run
      puts @options.inspect
      conn = Connection.new(@options[:connection])
      Engine.new(conn, @options[:engine]).run
    end

    private

    def _parse(argv, options)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: debloater [options] database"

        opts.on('-h HOST', 'Database host to connect to [localhost]') do |v|
          options[:connection][:host] = v
        end

        opts.on('-p PORT', 'Port to connect to [5432]') do |v|
          options[:connection][:port] = v
        end

        opts.on('-U USER', 'Username to connect with [postgres]') do |v|
          options[:connection][:user] = v
        end

        opts.on('-W', 'Prompt for password (default)') do
          options[:prompt_password] = true
        end

        opts.on('-w', 'No prompt for password') do
          options[:prompt_password] = false
        end

        opts.on('--auto', 'Do not ask for confirmation before debloating') do |v|
          options[:engine][:confirm] = false
        end

        opts.on('--min-mb [SIZE]', 'Do not debloat if the bloat size is lower than SIZE megabytes [50]') do |v|
          options[:engine][:min_mb] = v.to_f
        end

        opts.on('--max-density [FRACTION]', 'Do not debloat if the index density is higher than FRACTION [0.75]') do |v|
          options[:engine][:min_mb] = v.to_f
        end

        opts.on('--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      parser.parse!(argv)

      case argv.length
      when 1 then
        options[:connection][:dbname] = argv.pop
      else
        puts parser
        exit 1
      end

      if options[:prompt_password]
        options[:connection][:password] = IO.console.getpass('Enter password (no echo):')
      end
    end
  end
end
