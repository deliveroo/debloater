require 'pg'
require 'forwardable'
require 'debloater/helpers'

module Debloater
  class Connection
    include Helpers
    extend Forwardable

    def initialize(options)
      @pg = PG::Connection.open(options)

      exec %{
        SET statement_timeout = 0;
      }
    end

    def_delegators :@pg, :exec, :exec_params

    def statindex_method
      @_guessed_index_method ||=
        if _check_pgstatindex
          method = :pgstatindex
        elsif _check_get_pgstatindex
          method = :get_pgstatindex
        end
    end

    private

    def _check_pgstatindex
      exec %{
        select * from pgstatindex(0);
      }
    rescue PG::UndefinedFunction => e
      _fatal e, msg: 'The `pgstattuple` extension is missing. Consult the README.'
    rescue PG::InternalError
      # expected, as there is no index with OID zero
      true
    rescue PG::InsufficientPrivilege
      _log "`pgstatindex` not permitted, falling back to get_pgstatindex"
      false
    rescue PG::Error => e
      _fatal e
    end

    def _check_get_pgstatindex
      exec %{
        select * from get_pgstatindex(0);
      }
    rescue PG::UndefinedFunction => e
      _fatal e, msg: 'The `get_pgstatindex` function is not found. Consult the README.'
    rescue PG::InternalError
      # expected, as there is no index with OID zero
      true
    rescue PG::Error => e
      _fatal e
    end

  end
end
