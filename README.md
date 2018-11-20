[![CircleCI](https://circleci.com/gh/kalys/bamboo_ses.svg?style=svg)](https://circleci.com/gh/kalys/bamboo_ses)

# BambooSes

AWS SES adapter for Bamboo

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bamboo_ses` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bamboo_ses, "~> 0.1.0"}
  ]
end
```

## Configuration

Change the config for your mailer:

    config :my_app, MyApp.Mailer,
      adapter: Bamboo.SesAdapter

To find more on AWS key configuration please follow [this link](https://github.com/ex-aws/ex_aws#aws-key-configuration)

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bamboo_ses](https://hexdocs.pm/bamboo_ses).
