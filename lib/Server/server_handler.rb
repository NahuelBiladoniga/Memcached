class ServerHandler
  ADDRESS_ERRROR_MSG = "Address to bind server is invalid."
  CLIENT_OVERFLOW_ERROR = "Clients overflow."
  class AddressInvalid < StandardError
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
