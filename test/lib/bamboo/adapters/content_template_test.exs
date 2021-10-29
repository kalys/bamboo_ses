defmodule BambooSes.ContentTemplateTest do
  use ExUnit.Case
  alias BambooSes.Message.Content
  import BambooSes.TestHelpers

  test "generates template content when only template name is present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params("template name", nil, nil)
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateName: "template name"
             }
           }
  end

  test "generates template content when name and data are present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params("template name", ~s({"key":"value"}), nil)
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateName: "template name",
               TemplateData: ~s({"key":"value"})
             }
           }
  end

  test "generates template content when only arn is present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params(nil, nil, "template arn")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateArn: "template arn"
             }
           }
  end

  test "generates template content when arn and data are present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params(nil, ~s({"key":"value"}), "template arn")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateArn: "template arn",
               TemplateData: ~s({"key":"value"})
             }
           }
  end

  test "generates template content when arn and name are present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params("template name", nil, "template arn")
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateName: "template name",
               TemplateArn: "template arn"
             }
           }
  end

  test "generates template content when name, arn, and data are present" do
    content =
      new_email()
      |> Bamboo.SesAdapter.set_template_params(
        "template name",
        ~s({"key":"value"}),
        "template arn"
      )
      |> Content.build_from_bamboo_email()

    assert content == %Content{
             Template: %{
               TemplateName: "template name",
               TemplateArn: "template arn",
               TemplateData: ~s({"key":"value"})
             }
           }
  end
end
