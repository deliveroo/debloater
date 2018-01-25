require 'debloater/helpers'
require 'debloater/index'

module Debloater
  class Engine
    include Helpers

    def initialize(conn, confirm: true, min_mb: 50, max_density: 0.75)
      @conn = conn
      @confirm = confirm
      @min_mb = min_mb
      @max_density = max_density
    end


    def run
      debloated_indices = []
      Index.each(@conn) do |index|
        if index.pkey?
          _log "Skipping primary key index '#{index.name}'"
          next
        end

        unless index.valid?
          _log "Skipping invalid (non-Btree) index '#{index.name}'"
          next
        end

        puts format('%<name>-65s %<size>10d %<frag>3d pct %<bloat>6d MB' % {
          name:  index.name,
          size:  index.size,
          frag:  (100 - index.density * 100).to_i,
          bloat: index.bloat,
        })

        if index.bloat < @min_mb || index.density > @max_density
          _log "Skipping non-bloated index '#{index.name}'"
          next
        end

        if @confirm
          $stderr.write "debloat this index? [y/N] "
          next unless $stdin.gets.strip =~ /^y$/i
        end

        index.debloat!
        debloated_indices << index
      end
      debloated_indices
    end
  end
end
