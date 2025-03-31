open Lwt

let read in_chan out_chan =
  (* reading message header -- contains metadata *)
  let header_buf = Bytes.create Message.header_len in
  Lwt_io.read_into_exactly in_chan header_buf 0 Message.header_len >>= fun () ->
  let length = (Message.deserialize header_buf).length in
  (* buffer is being extended --  make sure to write into the correct position*)
  let message_buf = Bytes.extend header_buf 0 length in
  Lwt_io.read_into_exactly in_chan message_buf Message.header_len length
  >>= fun () ->
  let msg = Message.deserialize message_buf in
  match msg.message_type with
  | Ack ->
      let time_unit = "ms" in
      let milliseconds_per_second = 1000. in
      let now = Unix.gettimeofday () in
      let rtt = (now -. msg.timestamp) *. milliseconds_per_second in
      Lwt_io.printlf "%s (RTT %.3f%s)" msg.content rtt time_unit
  | Msg ->
      Lwt_io.printlf "> %s" msg.content >>= fun () ->
      let ack = Message.make Ack "Message recieved" in
      let ack_len = Message.header_len + ack.length in
      Lwt_io.write_from_exactly out_chan (Message.serialize ack) 0 ack_len

let write out_chan =
  Lwt_io.read_line Lwt_io.stdin >>= fun line ->
  let msg = Message.make Msg line in
  let msg_len = Message.header_len + msg.length in
  Lwt_io.write_from_exactly out_chan (Message.serialize msg) 0 msg_len

let rec message_loop in_chan out_chan () =
  let read_message = read in_chan out_chan in
  let write_message = write out_chan in
  Lwt.pick [ read_message; write_message ] >>= message_loop in_chan out_chan
