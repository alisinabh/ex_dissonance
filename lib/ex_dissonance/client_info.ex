defmodule ExDissonance.ClientInfo do
  use TypedStruct

  typedstruct enforce: true do
    field :player_id, non_neg_integer()
    field :player_name, String.t()
    field :codec_type, non_neg_integer()
    field :frame_size, non_neg_integer()
    field :sample_rate, non_neg_integer()
  end
end
