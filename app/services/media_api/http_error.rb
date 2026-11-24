module MediaApi
  class HttpError < Error
    attr_reader :status, :retry_after

    def initialize(status, retry_after = nil)
      @status = status
      @retry_after = retry_after
      super("Le fournisseur a répondu HTTP #{status}")
    end
  end
end
