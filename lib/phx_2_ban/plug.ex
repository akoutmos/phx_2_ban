defmodule Phx2Ban.Plug do
  @moduledoc """
  This Plug module is used to block requests from IP addresses
  that have been marked as malicious.
  """

  alias Phx2Ban.Telemetry
  alias Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts) do
    default_opts = %{
      analyze_request?: fn _conn -> true end,
      resp_status_code: 429,
      resp_body: "Too Many Requests",
      resp_headers: [
        {"retry-after", 360_000}
      ]
    }

    opts
    |> Map.new()
    |> Map.merge(default_opts)
  end

  @impl true
  def call(%Conn{} = conn, opts) do
    case Phx2Ban.validate_request_conn(conn) do
      :ok ->
        maybe_analyze_request(conn, opts.analyze_request?)

      :block ->
        Telemetry.execute_rejected_request(conn)

        conn
        |> Conn.resp(opts.resp_status_code, opts.resp_body)
        |> attach_resp_headers(opts.resp_headers)
        |> Conn.send_resp()
        |> Conn.halt()
    end
  end

  defp attach_resp_headers(%Conn{} = conn, resp_headers) do
    resp_headers
    |> Enum.reduce(conn, fn {key, value}, conn ->
      Conn.put_resp_header(conn, key, value)
    end)
  end

  defp maybe_analyze_request(%Conn{} = conn, analyze_request?) do
    if analyze_request?.(conn) do
      Conn.register_before_send(conn, fn ->
        Phx2Ban.analyze_request(conn)

        conn
      end)
    else
      conn
    end
  end
end
