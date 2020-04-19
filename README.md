![Elixir CI](https://github.com/kalys/bamboo_ses/workflows/Elixir%20CI/badge.svg)

# BambooSes

AWS SES adapter for Bamboo

## Installation

The package can be installed by adding `bamboo_ses` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bamboo_ses, "~> 0.1.0"}
  ]
end
```

## Configuration

Change the config for your mailer:

```elixir
config :my_app, MyApp.Mailer,
  adapter: Bamboo.SesAdapter
```

This package has [ExAws](https://github.com/ex-aws/ex_aws) as a dependency, and you have to configure it. To find more
on AWS key configuration, please follow [this link](https://github.com/ex-aws/ex_aws#aws-key-configuration).

You can also override the default ExAws configuration defining a Keyword list as `ex_aws` key in the mailer config:

```elixir
config :my_app, MyApp.Mailer,
  adapter: Bamboo.SesAdapter,
  ex_aws: [region: "eu-west-1"]
```

## Documentation

Documentation can be found at [https://hexdocs.pm/bamboo_ses](https://hexdocs.pm/bamboo_ses).
