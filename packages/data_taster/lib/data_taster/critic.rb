# frozen_string_literal: true

module DataTaster
  # Tracks the time, row count, and total size by table
  class Critic
    def self.track_sampling(&block)
      new.track_sampling(&block)
    end

    def track_sampling(&block)
      bm = Benchmark.measure(&block)

      DataTaster.logger.info("Dump completed in #{bm.real} seconds")
    end
  end
end
