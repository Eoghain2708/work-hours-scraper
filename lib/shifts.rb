require "bundler/setup"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))

require_relative "calculator"
require_relative "client"
require_relative "cli"
require_relative "dates"
require_relative "roster"
require_relative "shift_formatter"
require_relative "shifts"