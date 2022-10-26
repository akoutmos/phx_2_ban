defmodule Phx2Ban do
  @moduledoc """
  This process is responsible for setting up the firewall
  rules for the Phoenix application.
  """

  use Supervisor

  alias Phx2Ban.Analyzer
  alias Phx2Ban.Blacklist
  alias Plug.Conn

  # ---- Public API ----

  @doc false
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check to see if the incoming request is from a blocked IP address.
  """
  def validate_request_conn(%Conn{} = conn) do
    if Phx2Ban.Blacklist.valid_ip_address?(conn) do
      :ok
    else
      :block
    end
  end

  @doc """
  Analyze a request to see if the remote IP address should be blocked.
  """
  def analyze_request(%Conn{} = conn) do
    Phx2Ban.Analyzer.analyze_request(conn)
  end

  # ---- Supervisor Callbacks ----

  @impl true
  def init(opts) do
    children = [
      {Blacklist, opts},
      {Analyzer, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
