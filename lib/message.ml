type msg_type = Msg | Ack

(*              data layout         *)
(* 0------->+---------------------+ *)
(*          | msg_type  [4 bytes] | *)
(* 4------->+---------------------+ *)
(*          | timestamp [8 bytes] | *)
(* 12------>+---------------------+ *)
(*          | length    [4 bytes] | *)
(* 16------>+---------------------+ *)
(*          | content   [N bytes] | *)
(* (16+N)-->+---------------------+ *)
type message = {
  message_type : msg_type;
  timestamp : float;
  length : int;
  content : string;
}

(* config for magic numbers *)
let msg_type_offset = 0
let timestamp_offset = 4
let length_offset = 12
let header_len = 16

let int32_of_msg_type message_type =
  match message_type with Msg -> 0l | Ack -> 1l

let int32_to_msg_type int32 =
  match int32 with 0l -> Msg | 1l -> Ack | _ -> failwith "Invalid Int32 value"

(* sus way to convert float to bits -- serialize and deserialize; to and from int64 *)
let int64_of_timestamp timestamp = Int64.bits_of_float timestamp
let int64_to_timestamp int64 = Int64.float_of_bits int64

let make message_type content =
  let timestamp = Unix.gettimeofday () in
  let length = String.length content in
  { message_type; timestamp; length; content }

let serialize msg =
  let buffer = Bytes.create (header_len + msg.length) in
  Bytes.set_int32_ne buffer msg_type_offset (int32_of_msg_type msg.message_type);
  Bytes.set_int64_ne buffer timestamp_offset (int64_of_timestamp msg.timestamp);
  Bytes.set_int32_ne buffer length_offset (Int32.of_int msg.length);

  let content_bytes = Bytes.of_string msg.content in
  Bytes.blit content_bytes 0 buffer header_len msg.length;
  buffer

(* assume that atleast the header/metadata can be read *)
let deserialize bytes =
  let message_type =
    int32_to_msg_type (Bytes.get_int32_ne bytes msg_type_offset)
  in
  let timestamp =
    int64_to_timestamp (Bytes.get_int64_ne bytes timestamp_offset)
  in
  let length = Int32.to_int (Bytes.get_int32_ne bytes length_offset) in
  (* logic is weird because sometimes i just want to read the header *)
  let num_bytes_remaining = Bytes.length bytes - header_len in
  let content =
    Bytes.to_string (Bytes.sub bytes header_len num_bytes_remaining)
  in
  { message_type; timestamp; length; content }

(* tests and test helpers *)
let random_bytes length =
  let bytes = Bytes.create length in
  for i = 0 to length - 1 do
    Bytes.set bytes i (Char.chr (Random.int 256))
  done;
  bytes

let%test "assert field sizes and correct data layout" =
  let msg_type_size = timestamp_offset - msg_type_offset in
  let timestamp_size = length_offset - timestamp_offset in
  let length_size = header_len - length_offset in
  msg_type_size = 4 && timestamp_size = 8 && length_size = 4

let%test "serialize and deserialize msg" =
  let msg = make Msg "xd" in
  msg = deserialize (serialize msg)

let%test "serialize and deserialize ack" =
  let ack = make Ack "xd" in
  ack = deserialize (serialize ack)

let%test "serialize and deserialize msg with arbitrary bytes" =
  let length = Random.int 100 in
  let content = Bytes.to_string (random_bytes length) in
  let msg = make Msg content in
  msg = deserialize (serialize msg)

let%test "serialize and deserialize msg with no content" =
  let no_content = Bytes.to_string (Bytes.create 0) in
  let msg = make Msg no_content in
  msg = deserialize (serialize msg)

let%test "serialize and deserialize msg with arbitrary long bytes" =
  let long_content = Bytes.to_string (random_bytes 1_000_000) in
  let msg = make Msg long_content in
  msg = deserialize (serialize msg)

let%test "correctly serialized and deserialized timestamp" =
  let msg = make Msg "check timestamp" in
  let deserialized_msg = deserialize (serialize msg) in
  msg.timestamp = deserialized_msg.timestamp

let%test "correctly serialized and deserialized length" =
  let msg = make Msg "check length" in
  let deserialized_msg = deserialize (serialize msg) in
  msg.length = deserialized_msg.length

let%test "deserialize with invalid message_type should fail" =
  try
    let buffer = Bytes.create header_len in
    (* set invalid message type *)
    Bytes.set_int32_ne buffer msg_type_offset 2l;
    let _ = deserialize buffer in
    false
  with Failure _ -> true
