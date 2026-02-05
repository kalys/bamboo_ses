# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

BambooSes — an AWS SES v2 adapter for the Bamboo email library (Elixir). Published on Hex as `bamboo_ses`.

## Commands

```bash
mix deps.get                    # Install dependencies
mix test                        # Run all tests
mix test path/to/test.exs       # Run a single test file
mix test path/to/test.exs:42    # Run a single test at line 42
mix format                      # Format code
mix format --check-formatted    # Check formatting (CI)
mix credo                       # Lint
mix dialyzer                    # Type checking (slow first run; PLT cached in priv/plts/)
```

CI runs: `test → format --check-formatted → credo → dialyzer` (Elixir 1.18.x, OTP 28.x).

## Architecture

The adapter receives a `Bamboo.Email` struct and converts it into an AWS SES v2 `SendEmail` API call (`/v2/email/outbound-emails`) via `ex_aws`.

```
Bamboo.SesAdapter.deliver/2
  → BambooSes.Message.from_email/1     (compose full API request body)
      ├── Message.Content.build/1       (choose Simple | Raw | Template)
      │     └── Render.Raw.render/1     (MIME via :mimemail, for attachments/custom headers)
      ├── Message.Destination.build/1   (To/Cc/Bcc)
      └── Encoding                      (RFC1342 headers, IDNA/Punycode domains)
  → ExAws.Operation.JSON → AWS SES v2
```

**Content type selection** (`Message.Content`):
- **Template** — when template params are set via `set_template_params/3`
- **Raw** — when the email has attachments or custom headers (Base64-encoded MIME)
- **Simple** — plain text/HTML emails with no attachments

**Adapter-specific email metadata** is stored via `Bamboo.Email.put_private/3` (keys like `configuration_set_name`, `endpoint_id`, `template_name`, etc.) and exposed through public setter functions on `Bamboo.SesAdapter` (e.g., `set_configuration_set/2`, `set_email_tags/2`).

## Testing

- Tests use `Mox` to mock `ExAws.Request.HttpClient` as `ExAws.Request.HttpMock`.
- Test support modules live in `test/support/` (compiled via `elixirc_paths(:test)`): `TestHelpers.new_email/2` factory, `EmailParser` for decoding Base64 raw bodies, `HeaderItem` for header parsing.
- AWS credentials are set as env vars in test setup (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).
- Custom `Jason.Encoder` implementations on `Message` and `Destination` filter nil/empty values from the JSON payload.
