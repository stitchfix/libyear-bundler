module LibyearBundler
  module Calculators
    # The version sequence delta is the number of releases between the newest and
    # installed versions of the gem
    class VersionSequenceDelta
      class << self
        def calculate(installed_seq_index, newest_seq_index)
          return 0 if installed_seq_index.nil? || newest_seq_index.nil?

          installed_seq_index - newest_seq_index
        end
      end
    end
  end
end
