# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :devui,
  namespace: DevUI

# Configures the endpoint
config :devui, DevUI.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qVbpqnN1K3+cJOUHDhnvD3XS63qSgDyvvHNsFe+jy9DW+vJg+cBe0aW3oqJ8NH0U",
  render_errors: [view: DevUI.ErrorView, accepts: ~w(html json)],
  pubsub: [name: DevUI.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
