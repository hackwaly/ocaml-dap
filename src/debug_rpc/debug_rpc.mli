open Debug_protocol

type t

val create : in_:Lwt_io.input_channel -> out:Lwt_io.output_channel -> ?next_seq:int -> unit -> t
val event : t -> (module EVENT with type Body.t = 'a) -> 'a React.E.t
val send_event : t -> (module EVENT with type Body.t = 'a) -> 'a -> unit Lwt.t
val register_command : t -> (module COMMAND with type Request.Arguments.t = 'a and type Response.Body.t = 'b) -> (t -> 'a -> string -> 'b Lwt.t) -> unit
val exec_command : t -> (module COMMAND with type Request.Arguments.t = 'a and type Response.Body.t = 'b) -> 'a -> 'b Lwt.t
val start : t -> unit Lwt.t
