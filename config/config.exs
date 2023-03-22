import Config

if Mix.env() == :test do
  config :logger, level: :warn

  # config :logger,
  #   format: "$message\n",
  #   level: String.to_atom(System.get_env("LOG_LEVEL") || "info"),
  #   handle_otp_reports: true,
  #   handle_sasl_reports: true
end
