module Expect_test_config = struct
  include Expect_test_config
  module IO = struct
    type 'a t = 'a Lwt.t
    let return x = Lwt.return x
  end
  let run x = Lwt_main.run (x ())
end
