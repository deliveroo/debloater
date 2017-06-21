require 'debloater/helpers'

module Debloater
  class Index
    include Helpers

    # conn: connection object
    # method: the function used to obtain index information
    # name: the index name
    def initialize(conn, name:)
      @conn = conn
      @name = name
    end

    attr_reader :name

    def self.each(conn)
      data = conn.exec_params %{
        select * from pg_indexes where schemaname = $1
      }, ['public']
      data.sort_by { |d| 
        d['indexname'] 
      }.each { |d| 
        yield new(conn, name: d['indexname'])
      }
    rescue PG::Error => e
      _fatal e, msg: 'Could not list indexes'
    end


    def pkey?
      @name =~ /pkey/
    end


    def valid?
      !_metadata.nil?
    end


    def density
      @density ||= 0.01 * _metadata['avg_leaf_density'].to_f
    end


    def bloat
      @bloat ||= size * (1 - density)
    end


    def size
      @size ||= _metadata['index_size'].to_i / 1024**2
    end


    def debloat!
      [
        index['indexdef'].
          sub('CREATE INDEX', 'CREATE INDEX CONCURRENTLY').
          sub(indexname, "idx_debloat_new"),
        "BEGIN",
        "ALTER INDEX #{indexname} RENAME TO idx_debloat_old",
        "ALTER INDEX idx_debloat_new RENAME TO #{indexname}",
        "DROP INDEX idx_debloat_old",
        "COMMIT",
      ].each do |sql|
        _log "\t#{sql}"
        begin
          @conn.exec sql
        rescue PG::Error => e
          _fatal e, msg: "Failure during index debloating, you may need to recover manually."
        end
      end
    end


    private


    def _metadata
      return @_metadata if defined?(@_metadata)

      @_metadata = @conn.exec(%{
        select * from #{@conn.statindex_method}('#{@name}');
      }).to_a.first
    rescue PG::InvalidName
      _log "Invalid named index '#{@name}'"
      @_metadata = nil
    rescue PG::Error => e
      if e.message =~ /is not a btree index/
        _log "Invalid non-Btree index '#{@name}'"
        @_metadata = nil
      else
        _fatal e, msg: "Could not fetch metadata for index '#{@name}'"
      end
    rescue PG::Error => e
      binding.pry
    end
  end
end