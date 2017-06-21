module Debloater
  module Helpers
    def _log(line)
      $stderr.write("#{line}\n")
    end

    def _fatal(e, msg: nil)
      _log "Fatal error:"
      _log msg if msg

      _log "Exception: #{e.class.name}"
      _log "Details: #{e.message}"
      exit 1
    end
  end
end
