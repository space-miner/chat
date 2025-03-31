type msg_type = Msg | Ack

type message = {
  message_type : msg_type;
  timestamp : float;
  length : int;
  content : string;
}

val header_len : int

val make : msg_type -> string -> message

val serialize : message -> Bytes.t

val deserialize : Bytes.t -> message
