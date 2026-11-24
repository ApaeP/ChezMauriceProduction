module MediaApi
  class FrameIo
    module Pagination
      # Page links may carry the provider's opaque cursor, but must stay on
      # the same collection with the same unfiltered, unexpanded results.
      def self.each_item(api, collection, headers: {})
        path = collection
        seen = Set.new
        until path.nil?
          raise Error, "Lien de pagination Frame.io invalide" unless path.is_a?(String)
          uri = URI.parse(path)
          query = URI.decode_www_form(uri.query.to_s)
          unless uri.relative? && uri.host.nil? && uri.path == collection && uri.fragment.nil? &&
              query.all? { |key, _| %w[after page_size sort include_total_count].include?(key) } && seen.add?(path)
            raise Error, "Lien de pagination Frame.io invalide"
          end
          page = api.request(:get, "https://#{API_HOST}#{path}", headers: headers).json
          unless page.is_a?(Hash) && page["data"].is_a?(Array) && page["data"].all?(Hash) && page["links"].is_a?(Hash)
            raise Error, "Page Frame.io illisible"
          end
          page["data"].each { |item| yield item }
          path = page["links"]["next"]
        end
      rescue URI::Error
        raise Error, "Lien de pagination Frame.io invalide", cause: nil
      end
    end
  end
end
