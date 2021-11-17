# BambooSes

[![Elixir CI](https://github.com/kalys/bamboo_ses/actions/workflows/elixir.yml/badge.svg)](https://github.com/kalys/bamboo_ses/actions/workflows/elixir.yml)
[![Module Version](https://img.shields.io/hexpm/v/bamboo_ses.svg)](https://hex.pm/packages/bamboo_ses)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/bamboo_ses/)
[![Total Download](https://img.shields.io/hexpm/dt/bamboo_ses.svg)](https://hex.pm/packages/bamboo_ses)
[![License](https://img.shields.io/hexpm/l/bamboo_ses.svg)](https://github.com/kalys/bamboo_ses/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/kalys/bamboo_ses.svg)](https://github.com/kalys/bamboo_ses/commits/master)


AWS SES adapter for Bamboo

## Installation

The package can be installed by adding `:bamboo_ses` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bamboo_ses, "~> 0.2.0"}
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

You can also override the default ExAws configuration defining a Keyword list as `:ex_aws` key in the mailer config:

```elixir
config :my_app, MyApp.Mailer,
  adapter: Bamboo.SesAdapter,
  ex_aws: [region: "eu-west-1"]
```

## Usage

```elixir
email
|> Bamboo.SesAdapter.set_configuration_set("my-configuration-name")
|> TestBambooSes.Mailer.deliver_now()
```

See all available methods on https://hexdocs.pm/bamboo_ses/Bamboo.SesAdapter.html

## Copyright and License

Copyright (c) 2018 Kalys Osmonov

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file.
