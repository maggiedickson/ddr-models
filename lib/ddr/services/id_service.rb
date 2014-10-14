require 'noid'

module Ddr
  module Services
    module IdService

      def self.noid_template
        Ddr::Models.noid_template
      end

      @minter = ::Noid::Minter.new(template: noid_template)
      @semaphore = Mutex.new
      
      def self.valid? noid
        @minter.valid? noid
      end

      def self.mint
        @semaphore.synchronize do
          while true
            minted = MintedId.new(minted_id: self.next_id)
            return minted.minted_id if minted.save
          end
        end
      end

      protected

      def self.next_id
        noid = ''
        File.open(Ddr.Models::minter_statefile, File::RDWR|File::CREAT, 0644) do |f|
          f.flock(File::LOCK_EX)
          yaml = YAML::load(f.read)
          yaml = {template: noid_template} unless yaml
          minter = ::Noid::Minter.new(yaml)
          noid = minter.mint
          f.rewind
          yaml = YAML::dump(minter.dump)
          f.write yaml
          f.flush
          f.truncate(f.pos)
        end
        noid
      end

    end
  end
end