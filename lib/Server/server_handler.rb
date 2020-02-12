class ServerHandler
  ADDRESS_ERRROR_MSG = "Failed to bind address."
  CLIENT_OVERFLOW_ERROR = "Clients overflow."
  class BindingFailed < StandardError
    def message
      ADDRESS_ERRROR_MSG
    end
  end
  class ClientOverflow < StandardError
    def message
      CLIENT_OVERFLOW_ERROR
    end
  end
end
