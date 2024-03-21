defmodule FormDemoWeb.CoreComponents.SwiftUI do
  use FormDemoNative, [:component, format: :swiftui]

  @doc type: :component
  attr(:for, :any, required: true, doc: "An existing form or the form source data.")

  attr(:action, :string,
    doc: """
    The action to submit the form on.
    This attribute must be given if you intend to submit the form to a URL without LiveView.
    """
  )

  attr(:as, :atom,
    doc: """
    The prefix to be used in names and IDs generated by the form.
    For example, setting `as: :user_params` means the parameters
    will be nested "user_params" in your `handle_event` or
    `conn.params["user_params"]` for regular HTTP requests.
    If you set this option, you must capture the form with `:let`.
    """
  )

  attr(:csrf_token, :any,
    doc: """
    A token to authenticate the validity of requests.
    One is automatically generated when an action is given and the method is not `get`.
    When set to `false`, no token is generated.
    """
  )

  attr(:errors, :list,
    doc: """
    Use this to manually pass a keyword list of errors to the form.
    This option is useful when a regular map is given as the form
    source and it will make the errors available under `f.errors`.
    If you set this option, you must capture the form with `:let`.
    """
  )

  attr(:method, :string,
    doc: """
    The HTTP method.
    It is only used if an `:action` is given. If the method is not `get` nor `post`,
    an input tag with name `_method` is generated alongside the form tag.
    If an `:action` is given with no method, the method will default to `post`.
    """
  )

  attr(:multipart, :boolean,
    default: false,
    doc: """
    Sets `enctype` to `multipart/form-data`.
    Required when uploading files.
    """
  )

  attr(:rest, :global,
    include: ~w(autocomplete name rel enctype novalidate target),
    doc: "Additional HTML attributes to add to the form tag."
  )

  slot(:inner_block, required: true, doc: "The content rendered inside of the form tag.")

  def form(assigns) do
    action = assigns[:action]

    # We require for={...} to be given but we automatically handle nils for convenience
    form_for =
      case assigns[:for] do
        nil -> %{}
        other -> other
      end

    form_options =
      assigns
      |> Map.take([:as, :csrf_token, :errors, :method, :multipart])
      |> Map.merge(assigns.rest)
      |> Map.to_list()

    # Since FormData may add options, read the actual options from form
    %{options: opts} = form = to_form(form_for, form_options)

    # By default, we will ignore action, method, and csrf token
    # unless the action is given.
    attrs =
      if action do
        {method, opts} = Keyword.pop(opts, :method)
        {method, _} = form_method(method)

        [action: action, method: method] ++ opts
      else
        opts
      end

    attrs =
      case Keyword.pop(attrs, :multipart, false) do
        {false, attrs} -> attrs
        {true, attrs} -> Keyword.put(attrs, :enctype, "multipart/form-data")
      end

    attrs = Keyword.put(attrs, :id, Map.get(assigns.rest, :id, form_for.id))

    assigns =
      assign(assigns,
        form: form,
        attrs: attrs
      )

    ~LVN"""
    <LiveForm {@attrs}>
      <%= render_slot(@inner_block, @form) %>
    </LiveForm>
    """
  end

  defp form_method(nil), do: {"post", nil}
  defp form_method(method) when method in ~w(get post), do: {method, nil}
  defp form_method(method) when is_binary(method), do: {"post", method}

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "TextField",
    values: ~w(TextFieldLink DatePicker MultiDatePicker Picker SecureField Slider Stepper TextEditor TextField Toggle)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :min, :any, default: nil
  attr :max, :any, default: nil

  attr :placeholder, :string, default: nil

  attr :readonly, :boolean, default: false

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list maxlength minlength
                multiple pattern required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign(
      :rest,
      Map.put(assigns.rest, :class, ~s(#{Map.get(assigns.rest, :class, "")} #{if assigns.readonly or Map.get(assigns.rest, :disabled, false), do: "disabled-true", else: ""}))
    )
    |> input()
  end

  def input(%{type: "TextFieldLink"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <TextFieldLink id={@id} name={@name} value={@value} prompt={@prompt} {@rest}>
          <%= @label %>
        </TextFieldLink>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "DatePicker"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <DatePicker id={@id} name={@name} selection={@value} {@rest}>
          <%= @label %>
        </DatePicker>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "MultiDatePicker"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <MultiDatePicker id={@id} name={@name} selection={@value} {@rest}><%= @label %></MultiDatePicker>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "Picker"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <Picker id={@id} name={@name} selection={@value} {@rest}>
          <Text
            :for={{name, value} <- @options}
            tag={value}
          >
            <%= name %>
          </Text>
        </Picker>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "Slider"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <Slider id={@id} name={@name} value={@value} lowerBound={@min} upperBound={@max} {@rest}><%= @label %></Slider>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "Stepper"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <Stepper id={@id} name={@name} value={@value} {@rest}></Stepper>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "TextEditor"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <TextEditor id={@id} name={@name} text={@value} {@rest}><%= @placeholder || @label %></TextEditor>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "TextField"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <TextField id={@id} name={@name} text={@value} prompt={@prompt} {@rest}><%= @placeholder || @label %></TextField>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "SecureField"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <SecureField id={@id} name={@name} text={@value} prompt={@prompt} {@rest}><%= @placeholder || @label %></SecureField>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  def input(%{type: "Toggle"} = assigns) do
    ~LVN"""
    <VStack alignment="leading">
      <LabeledContent>
        <Text template="label"><%= @label %></Text>
        <Toggle id={@id} name={@name} isOn={@value} {@rest}></Toggle>
      </LabeledContent>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </VStack>
    """
  end

  slot :inner_block, required: true

  def error(assigns) do
    ~LVN"""
    <Group class="font-caption fg-red">
      <%= render_slot(@inner_block) %>
    </Group>
    """
  end

  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~LVN"""
    <VStack class={"navigation-title-:title navigation-subtitle-:subtitle toolbar--toolbar #{@class}"}>
      <Text template="title">
        <%= render_slot(@inner_block) %>
      </Text>
      <Text :if={@subtitle != []} template="subtitle">
        <%= render_slot(@subtitle) %>
      </Text>
      <ToolbarItem template="toolbar">
        <%= render_slot(@actions) %>
      </ToolbarItem>
    </VStack>
    """
  end

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~LVN"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <Form>
        <%= render_slot(@inner_block, f) %>
        <Section>
          <%= for action <- @actions do %>
            <%= render_slot(action, f) %>
          <% end %>
        </Section>
      </Form>
    </.form>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true
  def button(%{ type: "submit" } = assigns) do
    ~LVN"""
    <LiveSubmitButton>
      <%= render_slot(@inner_block) %>
    </LiveSubmitButton>
    """
  end
  def button(assigns) do
    ~LVN"""
    <Button>
      <%= render_slot(@inner_block) %>
    </Button>
    """
  end

  def table(assigns) do
    ~LVN"""
    <Table></Table>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(assigns) do
    ~LVN"""
    <Image systemName={@name} class={@class} />
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(FormDemoWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(FormDemoWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc type: :component
  attr(:navigate, :string,
    doc: """
    Navigates from a LiveView to a new LiveView.
    The browser page is kept, but a new LiveView process is mounted and its content on the page
    is reloaded. It is only possible to navigate between LiveViews declared under the same router
    `Phoenix.LiveView.Router.live_session/3`. Otherwise, a full browser redirect is used.
    """
  )

  # attr(:patch, :string,
  #   doc: """
  #   Patches the current LiveView.
  #   The `handle_params` callback of the current LiveView will be invoked and the minimum content
  #   will be sent over the wire, as any other LiveView diff.
  #   """
  # )

  attr(:href, :any,
    doc: """
    Uses traditional browser navigation to the new location.
    This means the whole page is reloaded on the browser.
    """
  )

  # `NavigationLink` always pushes a new page.
  # attr(:replace, :boolean,
  #   default: false,
  #   doc: """
  #   When using `:patch` or `:navigate`,
  #   should the browser's history be replaced with `pushState`?
  #   """
  # )

  attr(:method, :string,
    default: "get",
    doc: """
    The HTTP method to use with the link. This is intended for usage outside of LiveView
    and therefore only works with the `href={...}` attribute. It has no effect on `patch`
    and `navigate` instructions.

    In case the method is not `get`, the link is generated inside the form which sets the proper
    information. In order to submit the form, JavaScript must be enabled in the browser.
    """
  )

  attr(:csrf_token, :any,
    default: true,
    doc: """
    A boolean or custom token to use for links with an HTTP method other than `get`.
    """
  )

  attr(:rest, :global,
    include: ~w(download hreflang referrerpolicy rel target type),
    doc: """
    Additional HTML attributes added to the `a` tag.
    """
  )

  slot(:inner_block,
    required: true,
    doc: """
    The content rendered inside of the `a` tag.
    """
  )

  def link(%{navigate: to} = assigns) when is_binary(to) do
    ~LVN"""
    <NavigationLink destination={@navigate} {@rest}>
      <%= render_slot(@inner_block) %>
    </NavigationLink>
    """
  end

  # `patch` cannot be expressed with `NavigationLink`.
  # Use `push_patch` within `handle_event` to patch the URL.
  # def link(%{patch: to} = assigns) when is_binary(to) do
  #   ~LVN""
  # end

  def link(%{href: href} = assigns) when href != "#" and not is_nil(href) do
    href = Phoenix.LiveView.Utils.valid_destination!(href, "<.link>")
    assigns = assign(assigns, :href, href)

    ~LVN"""
    <Link destination={@href} {@rest}>
      <%= render_slot(@inner_block) %>
    </Link>
    """
  end

  def link(%{} = assigns) do
    ~LVN"""
    <NavigationLink destination="#" {@rest}>
      <%= render_slot(@inner_block) %>
    </NavigationLink>
    """
  end
end
