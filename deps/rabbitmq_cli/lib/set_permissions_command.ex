## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule SetPermissionsCommand do

  def set_permissions([], _) do
    {:not_enough_args, []}
  end

  def set_permissions([_|_] = args, _) when length(args) < 4 do
    {:not_enough_args, args}
  end

  def set_permissions([_|_] = args, _) when length(args) > 4 do
    {:too_many_args, args}
  end

  def set_permissions([user, conf, write, read], %{node: node_name, param: vhost} = opts) do
    info(user, opts)
    node_name
    |> Helpers.parse_node
    |> :rabbit_misc.rpc_call(
      :rabbit_auth_backend_internal,
      :set_permissions,
      [user, vhost, conf, write, read]
    )
  end

  def set_permissions([_, _, _, _] = args, %{node: _} = opts) do
    default_opts = Map.merge(opts, %{param: "/"})
    set_permissions(args, default_opts)
  end

  def usage, do: "set_permissions [-p <vhost>] <user> <conf> <write> <read>"

  defp info(_, %{quiet: true}), do: nil
  defp info(user, %{param: vhost}), do: IO.puts "Setting permissions for user \"#{user}\" in vhost \"#{vhost}\" ..."
end
