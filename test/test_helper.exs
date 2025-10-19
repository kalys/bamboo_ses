Application.ensure_all_started(:hackney)

Mox.defmock(ExAws.Request.HttpMock, for: ExAws.Request.HttpClient)

{:ok, [:iconv]} = Application.ensure_all_started(:iconv)

ExUnit.start()
