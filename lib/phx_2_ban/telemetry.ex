defmodule Phx2Ban.Telemetry do
  @moduledoc """
  This module contains functions to emit Telemetry events
  when requests are blocked, and also provides a debug logger
  implementation to output data when the incoming request was blocked.
  """

  require Logger

  alias Plug.Conn

  @logger_event_id "phx_2_ban_default_logger"

  def attach_logger(opts \\ []) do
    events = [
      [:phx_2_ban, :request, :rejected],
      [:phx_2_ban, :remote_ip, :blocked],
      [:phx_2_ban, :remote_ip, :unblocked]
    ]

    opts = Keyword.put_new(opts, :level, :debug)

    :telemetry.attach_many(@logger_event_id, events, &__MODULE__.handle_event/4, opts)
  end

  @doc """
  Detach the debugging logger so that log messages are no longer produced.
  """
  def detach_logger do
    :telemetry.detach(@logger_event_id)
  end

  @doc false
  def handle_event(event, _measurements, metadata, opts) do
    level = Keyword.fetch!(opts, :level)

    Logger.log(level, """
    Phx2Ban Event: #{inspect(event)}
    Phx2Ban Metadata: #{inspect(metadata)}
    """)
  end

  @doc false
  def execute_rejected_request(%Conn{request_path: request_path, remote_ip: remote_ip}) do
    :telemetry.execute(
      [:phx_2_ban, :request, :rejected],
      %{},
      %{request_path: request_path, remote_ip: remote_ip}
    )
  end

  @doc false
  def execute_blacklist_ip_blocked(remote_ip) do
    :telemetry.execute(
      [:phx_2_ban, :remote_ip, :blocked],
      %{},
      %{remote_ip: remote_ip}
    )
  end

  @doc false
  def execute_blacklist_ip_unblocked(remote_ip) do
    :telemetry.execute(
      [:phx_2_ban, :remote_ip, :unblocked],
      %{},
      %{remote_ip: remote_ip}
    )
  end
end
