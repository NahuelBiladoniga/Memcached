module Commands
  GET_CMD = "get"
  GETS_CMD = "gets"
  SET_CMD = "set"
  ADD_CMD = "add"
  REPLACE_CMD = "replace"
  CAS_CMD = "cas"
  APPEND_CMD = "append"
  PREPEND_CMD = "prepend"

  STORED_MSG = "STORED"
  NOT_STORED_MSG = "NOT_STORED"
  EXISTS_MSG = "EXISTS"
  NOT_FOUND_MSG = "NOT_FOUND"

  NO_REPLY = "noreply"
  END_LINE = "END"
  END_CLIENT = "q"

  RETRIVAL_CMDS = [GET_CMD, GETS_CMD]
  ADD_CMDS = [SET_CMD, ADD_CMD, REPLACE_CMD, CAS_CMD]
  CONCAT_CMD = [APPEND_CMD, PREPEND_CMD]
  STORAGE_CMDS  = ADD_CMDS + CONCAT_CMD
end
