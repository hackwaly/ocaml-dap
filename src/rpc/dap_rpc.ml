open Dap

(* TODO: Work in progress *)

type command_handler
type event_handler
type get_event = {
  poly: 'a. (module EVENT with type Body.t = 'a) -> 'a React.E.t
}

type t = {
  in_chan : Lwt_io.input_channel;
  out_chan : Lwt_io.output_channel;
  next_seq : int ref;
  command_handler_tbl : (string, command_handler) Hashtbl.t;
  event_event: Dap.Event.t React.E.t;
  events : (string, get_event) Hashtbl.t;
  ongoing_requests : (int, Dap.Request.t) Hashtbl.t;
  log : Yojson.Safe.t -> unit;
}

let dummy_log _ = ()

let make ~in_ ~out ?(log=dummy_log) =
  let (event_event, _) = React.E.create () in
  { in_chan = in_;
    out_chan = out;
    next_seq = ref 0;
    command_handler_tbl = Hashtbl.create 0;
    event_event;
    events = Hashtbl.create 0;
    ongoing_requests = Hashtbl.create 0;
    log }

let register_event rpc (module SpecEvent : EVENT) =
  let fmap_event e =
    let body = Option.value e.Event.body ~default:`Null in
    let r = SpecEvent.Body.of_yojson body |> Result.to_option in
    if Option.is_none r then (
      rpc.log (`Assoc [
        "level", `String "error";
        "message", `String "Decode event body fail";
        "context", `Assoc [
          "event", `String SpecEvent.event;
          "body", body
        ]
      ])
    );
    r
  in
  let event = rpc.event_event |> React.E.fmap fmap_event in
  let get_event : type a. (module EVENT with type Body.t = a) -> a React.E.t = fun _ -> Obj.magic event in
  Hashtbl.replace rpc.events SpecEvent.event {poly = get_event}

let event : type a. t -> (module EVENT with type Body.t = a) -> a React.E.t =
  fun rpc (module SpecEvent) ->
    let get_event = Hashtbl.find rpc.events SpecEvent.event in
    get_event.poly (module SpecEvent)

let next_seq rpc =
  let seq = !(rpc.next_seq) in
  incr rpc.next_seq;
  seq

let send_event : type a. t -> (module EVENT with type Body.t = a) -> a -> unit Lwt.t =
  fun rpc (module SpecEvent) event ->
    let body = SpecEvent.Body.to_yojson event in
    let json = (
      Event.make
        ~seq:(next_seq rpc)
        ~type_:Event.Type.Event
        ~event:SpecEvent.event
        ~body:(Some body)
      ()
      |> Event.to_yojson
      |> Yojson.Safe.to_string
    ) in
    Lwt_io.write rpc.out_chan json

