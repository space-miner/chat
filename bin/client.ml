open Lwt

let client host port =
  let sock = Lwt_unix.socket PF_INET SOCK_STREAM 0 in
  let addr = Unix.ADDR_INET (Unix.inet_addr_of_string host, port) in
  Lwt_unix.connect sock addr >>= fun () ->
  let in_chan = Lwt_io.of_fd ~mode:Input sock in
  let out_chan = Lwt_io.of_fd ~mode:Output sock in

  Lwt.finalize
    (fun () ->
      Lwt.catch (Lib.Message_handler.message_loop in_chan out_chan) (function
        | End_of_file -> Lwt_io.printl "Connection closed by server"
        | Unix.Unix_error (err, _, _) ->
            Lwt_io.printlf "Unix error, %s" (Unix.error_message err)
        | exn -> Lwt_io.printlf "Exception, %s" (Printexc.to_string exn)))
    (fun () -> Lwt_unix.close sock)

let () =
  let host, port =
    match Sys.argv with
    | [| _; arg1; arg2 |] -> (arg1, int_of_string arg2)
    | [| _; arg1 |] -> ("127.0.0.1", int_of_string arg1)
    | _ -> ("127.0.0.1", 8080)
  in
  Lwt_main.run (client host port)
