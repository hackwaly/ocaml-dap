open Debug_protocol

type t = {
  in_ : Lwt_io.input_channel;
  out : Lwt_io.output_channel;
  mutable next_seq : int;
}

module type EVENT = sig
  val type_ : string

  module Body : sig
    type t
    [@@deriving yojson]
  end
end

module type COMMAND = sig
  val type_ : string

  module Request : sig
    type t
    [@@deriving yojson]

    module Arguments : sig
      type t
      [@@deriving yojson]
    end
  end

  module Response : sig
    type t
    [@@deriving yojson]

    module Body : sig
      type t
      [@@deriving yojson]
    end
  end
end

let make ~in_ ~out ?(next_seq=0) () =
  { in_; out; next_seq }

let next_seq rpc =
  let seq = rpc.next_seq in
  rpc.next_seq <- rpc.next_seq + 1;
  seq

let exec_command : type arg res. t -> (module COMMAND with type Request.Arguments.t = arg and type Response.Body.t = res) -> arg -> res Lwt.t =
  assert false
