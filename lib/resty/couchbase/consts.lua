local _M = {
  _VERSION = '0.1-alpha'
}

_M.op_code = {
  Get                     = 0x00, -- implemented
  Set                     = 0x01, -- implemented
  Add                     = 0x02, -- implemented
  Replace                 = 0x03, -- implemented
  Delete                  = 0x04, -- implemented
  Increment               = 0x05, -- implemented
  Decrement               = 0x06, -- implemented
  Quit                    = 0x07, -- implemented
  Flush                   = 0x08, -- implemented
  GetQ                    = 0x09, -- throws unsupported
  Noop                    = 0x0a, -- implemented
  Version                 = 0x0b, -- implemented
  GetK                    = 0x0c, -- implemented
  GetKQ                   = 0x0d, -- throws unsupported
  Append                  = 0x0e, -- implemented
  Prepend                 = 0x0f, -- implemented
  Stat                    = 0x10, -- implemented
  SetQ                    = 0x11, -- implemented
  AddQ                    = 0x12, -- implemented
  ReplaceQ                = 0x13, -- implemented
  DeleteQ                 = 0x14, -- implemented
  IncrementQ              = 0x15, -- implemented
  DecrementQ              = 0x16, -- implemented
  QuitQ                   = 0x17, -- not supported directly by API
  FlushQ                  = 0x18, -- throws unsupported
  AppendQ                 = 0x19, -- implemented
  PrependQ                = 0x1a, -- implemented
  Verbosity               = 0x1b, -- implemented
  Touch                   = 0x1c, -- implemented
  GAT                     = 0x1d, -- implemented
  GATQ                    = 0x1e, -- implemented
  HELO                    = 0x1f,
  SASL_List               = 0x20,
  SASL_Auth               = 0x21,
  SASL_Step               = 0x22,
  Ioctl_get               = 0x23,
  Ioctl_set               = 0x24,
  Cfg_validate            = 0x25,
  Cfg_reload              = 0x26,
  Audit_put               = 0x27,
  Audit_cfg_reload        = 0x28,
  Shutdown                = 0x29,
  RGet                    = 0x30,
  RSet                    = 0x31,
  RSetQ                   = 0x32,
  RAppend                 = 0x33,
  RAppendQ                = 0x34,
  RPrepend                = 0x35,
  RPrependQ               = 0x36,
  RDelete                 = 0x37,
  RDeleteQ                = 0x38,
  RIncr                   = 0x39,
  RIncrQ                  = 0x3a,
  RDecr                   = 0x3b,
  RDecrQ                  = 0x3c,
  Set_VBucket             = 0x3d,
  Get_VBucket             = 0x3e,
  Del_VBucket             = 0x3f,
  TAP_Connect             = 0x40,
  TAP_Mutation            = 0x41,
  TAP_Delete              = 0x42,
  TAP_Flush               = 0x43,
  TAP_Opaque              = 0x44,
  TAP_VBucket_Set         = 0x45,
  TAP_Checkout_Start      = 0x46,
  TAP_Checkpoint_End      = 0x47,
  Get_all_vb_seqnos       = 0x48,
  Dcp_Open                = 0x50,
  Dcp_add_stream          = 0x51,
  Dcp_close_stream        = 0x52,
  Dcp_stream_req          = 0x53,
  Dcp_get_failover_log    = 0x54,
  Dcp_stream_end          = 0x55,
  Dcp_snapshot_marker     = 0x56,
  Dcp_mutation            = 0x57,
  Dcp_deletion            = 0x58,
  Dcp_expiration          = 0x59,
  Dcp_flush               = 0x5a,
  Dcp_set_vbucket_state   = 0x5b,
  Dcp_noop                = 0x5c,
  Dcp_buffer_ack          = 0x5d,
  Dcp_control             = 0x5e,
  Dcp_reserved4           = 0x5f,
  Stop_persistence        = 0x80,
  Start_persistence       = 0x81,
  Set_param               = 0x82,
  Get_replica             = 0x83,
  Create_bucket           = 0x85,
  Delete_bucket           = 0x86,
  List_buckets            = 0x87,
  Select_bucket           = 0x89,
  Assume_role             = 0x8a,
  Observe_seqno           = 0x91,
  Observe                 = 0x92,
  Evict_key               = 0x93,
  Get_locked              = 0x94,
  Unlock_key              = 0x95,
  Last_closed_checkpoint  = 0x97,
  Deregister_tap_client   = 0x9e,
  Reset_replication_chain = 0x9f,
  Get_meta                = 0xa0,
  Getq_meta               = 0xa1,
  Set_with_meta           = 0xa2,
  Setq_with_meta          = 0xa3,
  Add_with_meta           = 0xa4,
  Addq_with_meta          = 0xa5,
  Snapshot_vb_states      = 0xa6,
  Vbucket_batch_count     = 0xa7,
  Del_with_meta           = 0xa8,
  Delq_with_meta          = 0xa9,
  Create_checkpoint       = 0xaa,
  Notify_vbucket_update   = 0xac,
  Enable_traffic          = 0xad,
  Disable_traffic         = 0xae,
  Change_vb_filter        = 0xb0,
  Checkpoint_persistence  = 0xb1,
  Return_meta             = 0xb2,
  Compact_db              = 0xb3,
  Set_cluster_config      = 0xb4,
  Get_cluster_config      = 0xb5,
  Get_random_key          = 0xb6,
  Seqno_persistence       = 0xb7,
  Get_keys                = 0xb8,
  Set_drift_counter_state = 0xc1,
  Get_adjusted_time       = 0xc2,
  Subdoc_get              = 0xc5,
  Subdoc_exists           = 0xc6,
  Subdoc_dict_add         = 0xc7,
  Subdoc_dict_upsert      = 0xc8,
  Subdoc_delete           = 0xc9,
  Subdoc_replace          = 0xca,
  Subdoc_array_push_last  = 0xcb,
  Subdoc_array_push_first = 0xcc,
  Subdoc_array_insert     = 0xcd,
  Subdoc_array_add_unique = 0xce,
  Subdoc_counter          = 0xcf,
  Subdoc_multi_lookup     = 0xd0,
  Subdoc_multi_mutation   = 0xd1,
  Subdoc_get_count        = 0xd2,
  Scrub                   = 0xf0,
  Isasl_refresh           = 0xf1,
  Ssl_certs_refresh       = 0xf2,
  Get_cmd_timer           = 0xf3,
  Set_ctrl_token          = 0xf4,
  Get_ctrl_token          = 0xf5,
  Init_complete           = 0xf6
}

-- Memcached status codes

_M.status = {
  NO_ERROR              = 0x0000,
  KEY_NOT_FOUND         = 0x0001,
  KEY_EXISTS            = 0x0002,
  VALUE_TOO_LARGE       = 0x0003,
  INVALID_ARGUMENT      = 0x0004,
  ITEM_NOT_STORED       = 0x0005,
  INVALID_INCR_DECR_VAL = 0x0006,
  VBUCKET_MOVED         = 0x0007,
  VBUCKED_NOT_CONNECTED = 0x0008,
  REAUTHENTICATE        = 0x001f,
  AUTH_ERROR            = 0x0020,
  AUTH_CONTINUE         = 0x0021,
  RANGE_ERROR           = 0x0022,
  ROLLBACK_REQUIRED     = 0x0023,
  NO_ACCESS             = 0x0024,
  NODE_IS_BEING_INIT    = 0x0025,
  UNKNOWN_COMMAND       = 0x0081,
  OUT_OF_MEMORY         = 0x0082,
  NOT_SUPPORTED         = 0x0083,
  INTERNAL_ERROR        = 0x0084,
  BUSY                  = 0x0085,
  TEMPORARY_FAILURE     = 0x0086,
  SUBDOC_ERRORS_BEGIN   = 0x00c0,
  SUBDOC_ERRORS_END     = 0x00cd
}

_M.status_desc = { 
  [0x0000] = "No error",
  [0x0001] = "Key not found",
  [0x0002] = "Key exists",
  [0x0003] = "Value too large",
  [0x0004] = "Invalid arguments",
  [0x0005] = "Item not stored",
  [0x0006] = "Incr/Decr on a non-numeric value",
  [0x0007] = "The vbucket belongs to another server",
  [0x0008] = "The connection is not connected to a bucket",
  [0x001f] = "The authentication context is stale, please re-authenticate",
  [0x0020] = "Authentication error",
  [0x0021] = "Authentication continue",
  [0x0022] = "The requested value is outside the legal ranges",
  [0x0023] = "Rollback required",
  [0x0024] = "No access",
  [0x0025] = "The node is being initialized",
  [0x0081] = "Unknown command",
  [0x0082] = "Out of memory",
  [0x0083] = "Not supported",
  [0x0084] = "Internal error",
  [0x0085] = "Busy",
  [0x0086] = "Temporary failure",
  [0x00c0] = "(Subdoc) The provided path does not exist in the document",
  [0x00c1] = "(Subdoc) One of path components treats a non-dictionary as a dictionary, or a non-array as an array",
  [0x00c2] = "(Subdoc) The path’s syntax was incorrect",
  [0x00c3] = "(Subdoc) The path provided is too large; either the string is too long, or it contains too many components",
  [0x00c4] = "(Subdoc) The document has too many levels to parse",
  [0x00c5] = "(Subdoc) The value provided will invalidate the JSON if inserted",
  [0x00c6] = "(Subdoc) The existing document is not valid JSON",
  [0x00c7] = "(Subdoc) The existing number is out of the valid range for arithmetic ops",
  [0x00c8] = "(Subdoc) The operation would result in a number outside the valid range",
  [0x00c9] = "(Subdoc) The requested operation requires the path to not already exist, but it exists",
  [0x00ca] = "(Subdoc) Inserting the value would cause the document to be too deep",
  [0x00cb] = "(Subdoc) An invalid combination of commands was specified",
  [0x00cc] = "(Subdoc) Specified key was successfully found, but one or more path operations failed." ..
             " Examine the individual lookup_result (MULTI_LOOKUP) / mutation_result (MULTI_MUTATION) structures for details.",
  [0x00cd] = "(Subdoc) Operation completed successfully on a deleted document"
}

-- extras consts

local encoder = require "resty.couchbase.encoder"

_M.deadbeef = encoder.pack_bytes(4, 0xde, 0xad, 0xbe, 0xef)

return _M