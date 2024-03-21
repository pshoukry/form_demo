defmodule FormDemoWeb.UserLoginLive.SwiftUI do
  use FormDemoNative, [:render_component, format: :swiftui]

  import FormDemoWeb.CoreComponents.SwiftUI

  def render(assigns, _) do
    ~LVN"""
    <.header class="text-center">
      Sign in to account
      <:actions>
        <.link navigate={~p"/users/register"} class="font-weight-semibold fg-tint">
          Sign up
        </.link>
      </:actions>
    </.header>

    <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
      <Section>
        <.input field={@form[:email]} type="TextField" label="Email" required />
        <.input field={@form[:password]} type="SecureField" label="Password" required />

        <Group template="footer">
          <.link navigate={~p"/users/reset_password"} class="font-caption font-weight-semibold">
            Forgot your password?
          </.link>
        </Group>
      </Section>

      <Section>
        <.input field={@form[:remember_me]} type="Toggle" label="Keep me logged in" />
      </Section>

      <:actions>
        <.button type="submit">
          <HStack>
            <Text>Sign in</Text>
            <Spacer />
            <Image systemName="arrow.right" />
          </HStack>
        </.button>
      </:actions>
    </.simple_form>
    """
  end
end
