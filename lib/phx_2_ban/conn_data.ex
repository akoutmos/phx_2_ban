defmodule Phx2Ban.ConnData do
  @moduledoc """
  This module exposes a struct that contains a trimmed down
  version of the `Plug.Conn` struct. This is then passed
  to each of the filter functions to test if the incoming
  request should be categorized as malicious.
  """

  alias Plug.Conn

  defstruct [:remote_ip, :method, :request_path, :status]

  @doc """
  Convert a `Plug.Conn` struct to a `Phx2Ban.ConnData` struct
  """
  def from_conn(%Conn{} = conn) do
    %__MODULE__{
      remote_ip: conn.remote_ip,
      method: conn.method,
      request_path: conn.request_path,
      status: conn.status
    }
  end
end
