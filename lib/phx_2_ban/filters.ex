defmodule Phx2Ban.Filters do
  @moduledoc """
  This module provides some default filters that you can use in
  your application, or can provide some inspiration for your
  own filters.
  """

  alias Phx2Ban.ConnData

  @doc """
  This rule will flag common path extensions that belong to other (and commonly
  exploited) languages such as PHP, .NET, and Java as well as OS extensions like
  Windows.
  """
  def common_extensions(%ConnData{request_path: request_path}) do
    Regex.match?(~r/\.(?:php|jsp|cgi|cfm|exe|bat|dll|asp|aspx|ini)$/, request_path)
  end

  @doc """
  This rule will flag requests that aim to find PHP files.
  """
  def php_file_extensions(%ConnData{request_path: request_path}) do
    Regex.match?(~r/\.php.(?:tmp|bkp|old|orig|swp|temp|copy|backup|save)$/, request_path)
  end

  @doc """
  This rule will flag requests that aim to extract files from the OS.
  """
  def linux_files(%ConnData{request_path: request_path}) do
    Regex.match?(
      ~r/\.(?:htaccess|git|bashrc|zshrc|cvs|passwd|web|gitignore|svnignore|htpasswd)$/,
      request_path
    )
  end
end
