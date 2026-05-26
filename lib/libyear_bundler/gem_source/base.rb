module LibyearBundler
  module GemSource
    class Base
      def release_date(_name, _version)
        raise NotImplementedError
      end

      def versions_sequence(_name)
        raise NotImplementedError
      end
    end
  end
end
