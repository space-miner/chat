### Build and Run
Start with running dune build
`dune build`

To start the server
`dune exec server <optional: port>`

To start a client
`dune exec client <optional: host> <optional: port>`

You can now begin sending message between the two.

### Project Structure
```
tsuy@T480s:~/proj/chat$ tree
.
├── bin
│   ├── client.ml
│   ├── dune
│   └── server.ml
├── chat.opam
├── dune-project
├── lib
│   ├── dune
│   ├── message_handler.ml
│   ├── message.ml
│   └── message.mli
├── readme.md
└── test
    ├── dune
    └── test_chat.ml
```


### TODO
- [x] close server socket
- [x] handle only 1 connection
  - [x] need to terminate the extra clients trying to connect 
- [x] figure out timer
- [x] remove magic numbers
- [x] write test
- [x] choose infix bind (over `let%lwt` and `let*`)
  - [x] [online discussion](https://discuss.ocaml.org/t/lwt-now-has-let-syntax/5651/2)(`let%lwt` provides better backtraces, but will need a ppx dependency)
- [x] Tested on OCaml `5.0.0` and `4.13.1`

### Resources
- [Raphael Proust's Lwt Tutorial](https://raphael-proust.github.io/code/lwt-part-1.html)
- [Ocaml Unix book (socket chapter)](https://ocaml.github.io/ocamlunix/sockets.html)
- [Lwt in 5 minutes](https://ocsigen.org/tuto/latest/manual/lwt)
- [Lwt\_io docs](https://ocsigen.org/lwt/3.2.1/api/Lwt_io)
- [Lwt\_unix docs](https://ocsigen.org/lwt/3.3.0/api/Lwt_unix)
- [Stdlib Unix docs](https://ocaml.org/manual/5.3/api/Unix.html)
- [Stdlib Byte docs](https://ocaml.org/manual/5.1/api/Bytes.html)
- [Stdlib Int64 docs](https://ocaml.org/manual/5.2/api/Int64.html)
