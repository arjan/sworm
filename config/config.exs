import Config

if Mix.env() == :test do
  config :logger, level: :warn
end
