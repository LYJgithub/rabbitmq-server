## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at https://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.

defmodule RabbitMQ.CLI.Diagnostics.Commands.CheckCertificateExpirationCommand do
  alias RabbitMQ.CLI.Core.DocGuide
  alias RabbitMQ.CLI.TimeUnit, as: TU
  @behaviour RabbitMQ.CLI.CommandBehaviour

  import RabbitMQ.CLI.Core.Listeners

  def switches(), do: [unit: :string, within: :integer]

  def merge_defaults(args, opts) do
    {args, Map.merge(%{unit: "days", within: 1}, opts)}
  end

  def validate(args, _) when length(args) > 0 do
    {:validation_failure, :too_many_args}
  end
  def validate(_, %{unit: unit}) do
    case TU.known_unit?(unit) do
      true ->
        :ok

      false ->
        {:validation_failure, "unit '#{unit}' is not supported. Please use one of: days, weeks, months, years"}
    end
  end
  def validate(_, _), do: :ok

  def run([], %{node: node_name, unit: unit, within: within, timeout: timeout}) do
    case :rabbit_misc.rpc_call(node_name, :rabbit_networking, :active_listeners, [], timeout) do
      {:error, _} = err ->
        err

      {:error, _, _} = err ->
        err

      {:badrpc, _} = err ->
        err

      xs when is_list(xs) ->
        listeners = listeners_on(xs, node_name)
        seconds = TU.convert(within, unit)
        Enum.reduce(listeners, [], fn (listener, acc) -> case listener_expiring_within(listener, seconds) do
                                                           false -> acc
                                                           expiring -> [expiring | acc]
                                                         end
        end)
    end
  end

  def output([], %{formatter: "json"}) do
    {:ok, %{"result" => "ok"}}
  end

  def output([], %{unit: unit, within: within}) do
    {:ok, "No certificates are expiring within #{within} #{unit}."}
  end

  def output(listeners, %{formatter: "json"}) do
    {:error, :check_failed, %{"result" => "error", "expired" => Enum.map(listeners, &expired_listener_map/1)}}
  end
  
  def output(listeners, %{}) do
    {:error, :check_failed, Enum.map(listeners, &expired_listener_map/1)}
  end

  def usage, do: "check_certificate_expiration"

  def usage_doc_guides() do
    [
      DocGuide.configuration(),
      DocGuide.tls()
    ]
  end

  def help_section(), do: :observability_and_health_checks

  def description(), do: "Checks the expiration date on the certificates for every listener configured to use TLS"

  def banner(_, %{node: node_name}), do: "Expired certificates of node #{node_name} ..."
end
