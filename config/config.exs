# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :opentok_liveview, OpentokLiveviewWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "n7KB98nrOImX+lJhmgKmIZ2Nan0iBaaAyg6aj4E+8NCBnyyTApc956x40bndI2vr",
  render_errors: [view: OpentokLiveviewWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: OpentokLiveview.PubSub,
  live_view: [signing_salt: "rK/gCehp"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
