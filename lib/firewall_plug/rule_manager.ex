defmodule Phx2Ban.RuleManger do
  @doc """
  This process is responsible for setting up the firewall
  rules for the Phoenix application.
  """

  use GenServer

  alias Plug.Conn

  @ip_filter_key {__MODULE__, :ip_filter}
  @regex_blacklist_key {__MODULE__, :regex_list}

  @cuckoo_filter_capacity 2 ** 16

  # ---- Public API ----

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  This function provides a default list of paths that should result
  in a banned IP address. While not as complete as https://github.com/fail2ban/fail2ban
  in terms of requests that are flagged as invalid, most site scanning tools
  look for Wordpress, Java and Microsoft servers and these default rules are enough to
  catch most offeneding requesters.
  """
  def default_regex_list do
    [
      # Common file extensions from other web frameworks/languages
      ~r/\.(?:php|jsp|cgi|cfm|exe|bat|dll|asp|aspx|ini)$/,
      ~r/\.php.(?:tmp|bkp|old|orig|swp|temp|copy|backup|save)$/,

      # Common Linux files
      ~r/\.(?:htaccess|git|bashrc|zshrc|cvs|passwd|web|gitignore|svnignore|htpasswd$/
    ]
  end

  @doc """
  """
  def validate_conn_request(%Conn{} = conn) do
    # We check for false here as opposed to true since Cuckoo filters
    # guarantee that the element is "definitely not in set" but checking for
    # true would trip the "possibly in set" behaviour.

    with false <- blacklisted_ip_address?(conn),
         false <- invalid_request_path?(conn) do
      :ok
    else
      _ ->
        :block
    end
  end

  defp blacklisted_ip_address?(%Conn{remote_ip: nil}) do
    false
  end

  defp blacklisted_ip_address?(%Conn{remote_ip: remote_ip}) do
    blacklisted_ip_address =
      @ip_filter_key
      |> :persistent_term.get()
      |> :cuckoo_filter.contains(remote_ip)

    if blacklisted_ip_address do
      # TELEMETRY EVENT
    end

    blacklisted_ip_address
  end

  defp invalid_request_path?(%Conn{request_path: request_path, remote_ip: remote_ip}) do
    invalid_request_path? =
      @regex_blacklist_key
      |> Enum.any?(fn regex_pattern ->
        Regex.match?(regex_pattern, request_path)
      end)

    # Add this new IP to the IP blacklist
    if invalid_request_path? do
      @ip_filter_key
      |> :persistent_term.get()
      |> :cuckoo_filter.add(remote_ip)
    end

    invalid_request_path?
  end

  # ---- Server Callbacks ----

  @impl true
  def init(opts) do
    # This always needs to be set up in order to quickly get the rejected IP addresses
    :persistent_term.put(@ip_filter_key, :cuckoo_filter.new(@cuckoo_filter_capacity))

    # Add regex filters
    :persistent_term.put(
      @regex_blacklist_key,
      Keyword.get(opts, :invalid_request_path_patterns, default_regex_list())
    )

    {:ok, opts}
  end
end
