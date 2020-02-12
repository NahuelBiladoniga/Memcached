class ClientHandler
  ADDRESS_INVALID_MSG = "Could not connect to server, invalid address or port."
  CONNECTION_NOT_ESTABLISHED_MSG = "Connection with the server has not been established."

  class InvalidServerAddress < StandardError
    def message
      ADDRESS_INVALID_MSG
    end
  end
  class InvalidParameters < StandardError
    def message(message)
      message
    end
  end
  class ClientNotConnected < StandardError
    def message
      CONNECTION_NOT_ESTABLISHED_MSG
    end
  end

end
