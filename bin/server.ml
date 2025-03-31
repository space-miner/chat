open Lwt

exception TooManyConnections

let conn_limit = 1
let conns = ref 0

let try_handle_client client_sock () =
  Lwt.catch
    (fun () ->
      if !conns < conn_limit then (
        incr conns;
        let in_chan = Lwt_io.of_fd ~mode:Input client_sock in
        let out_chan = Lwt_io.of_fd ~mode:Output client_sock in
        Lwt.catch (Lib.Message_handler.message_loop in_chan out_chan)
          (fun exn ->
            decr conns;
            Lwt.fail exn))
      else Lwt.fail TooManyConnections)
    (function
      | TooManyConnections -> Lwt_io.printlf "Too many connections"
      | End_of_file -> Lwt_io.printlf "Client disconnected"
      | Unix.Unix_error (err, _, _) ->
          Lwt_io.printlf "Unix Error, %s" (Unix.error_message err)
      | exn -> Lwt_io.printlf "Exception, %s" (Printexc.to_string exn))

let rec accept_connection_loop sock () =
  Lwt_io.printl "Waiting for connection..." >>= fun () ->
  Lwt_unix.accept sock >>= fun (client_sock, _) ->
  Lwt_io.printl "Accepted client connection" >>= fun () ->
  (* flush everything from stdin -- i.e. in case server writes to stdin before client connects *)
  Lwt_unix.tcflush Lwt_unix.stdin TCIOFLUSH >>= fun () ->
  (* run asynchronously, so extra clients trying to connect will be dropped*)
  Lwt.async (fun () ->
      Lwt.finalize (try_handle_client client_sock) (fun () ->
          Lwt_io.printlf "Closing client socket" >>= fun () ->
          Lwt_unix.close client_sock));
  accept_connection_loop sock ()

let server port =
  let sock = Lwt_unix.socket PF_INET SOCK_STREAM 0 in
  let addr = Unix.ADDR_INET (Unix.inet_addr_loopback, port) in
  Lwt_unix.setsockopt sock SO_REUSEADDR true;
  Lwt_unix.bind sock addr >>= fun () ->
  Lwt_unix.listen sock 1;

  Lwt.finalize (accept_connection_loop sock) (fun () -> Lwt_unix.close sock)

let () =
  let port =
    if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 8080
  in
  Lwt_main.run (server port)
