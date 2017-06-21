require 'debloater/helpers'

module Debloater
  class Index
    include Helpers

    # conn: connection object
    # method: the function used to obtain index information
    # name: the index name
    def initialize(conn, name:, sql:)
      @conn = conn
      @name = name
      @sql = sql
    end

    attr_reader :name

    def self.each(conn)
      data = conn.exec_params %{
        select * from pg_indexes where schemaname = $1
      }, ['public']
      data.sort_by { |d| 
        d['indexname'] 
      }.each { |d| 
        next if d['indexname'] =~ /idx_debloat/
        yield new(conn, name: d['indexname'], sql: d['indexdef'])
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
      _log "Old index definition:"
      _log @sql

      [
        'DROP INDEX IF EXISTS idx_debloat_new',
        @sql.
          sub(/CONCURRENTLY/i, '').
          sub(/CREATE\s+(UNIQUE\s+)?INDEX/i, 'CREATE \1INDEX CONCURRENTLY').
          sub(@name, 'idx_debloat_new'),
        %{
          BEGIN;
          ALTER INDEX #{@name} RENAME TO idx_debloat_old;
          ALTER INDEX idx_debloat_new RENAME TO #{@name};
          DROP INDEX idx_debloat_old;
          COMMIT;
        },
      ].each do |sql|
        begin
          _log "\t#{sql}"
          @conn.exec sql
        rescue PG::TRDeadlockDetected => e
          _log "Deadlock encountered. Press enter to retry, ^C to abort."
          IO.console.gets
          @conn.exec 'ROLLBACK;'
          retry
        rescue PG::DependentObjectsStillExist => e
          _log "Could not debloat '#{@name}', skipping. Details:"
          _log e.message
        rescue PG::Error => e
          _fatal e, msg: "Failure during index debloating, you may want to delete the temporary index 'idx_debloat_new' manually."
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
    end
  end
end
