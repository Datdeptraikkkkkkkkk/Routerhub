if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local environment = (type(getgenv) == "function" and getgenv()) or _G
environment.Theme = environment.Theme or {}
environment.Theme.Color = environment.Theme.Color or {}

-- Theme migration
local THEME_VERSION = 7
local shouldRefreshTheme = environment.Theme.UseCustomPalette ~= true
	and (environment.Theme.__GamzThemeVersion == nil or environment.Theme.__GamzThemeVersion < THEME_VERSION)

if shouldRefreshTheme then
	environment.Theme.Color.First = nil
	environment.Theme.Color.Second = nil
	environment.Theme.Background = nil
	environment.Theme.Sidebar = nil
	environment.Theme.Card = nil
	environment.Theme.Control = nil
	environment.Theme.Text = nil
	environment.Theme.Muted = nil
	environment.Theme.Border = nil
	environment.Theme.ToggleOn = nil
end
environment.Theme.__GamzThemeVersion = THEME_VERSION

-- inspired graphite & obsidian palette
environment.Theme.Color.First = environment.Theme.Color.First or Color3.fromRGB(52, 138, 255)
environment.Theme.Color.Second = environment.Theme.Color.Second or Color3.fromRGB(38, 98, 235)

local Theme = environment.Theme
local Palette = {
	Background = Theme.Background or Color3.fromRGB(17, 18, 23),
	Sidebar = Theme.Sidebar or Color3.fromRGB(14, 15, 19),
	Card = Theme.Card or Color3.fromRGB(22, 23, 30),
	CardBorder = Color3.fromRGB(36, 38, 50),
	Control = Theme.Control or Color3.fromRGB(28, 30, 40),
	ControlHover = Color3.fromRGB(36, 38, 50),
	Text = Theme.Text or Color3.fromRGB(242, 244, 250),
	Muted = Theme.Muted or Color3.fromRGB(138, 142, 160),
	Subtle = Color3.fromRGB(92, 95, 112),
	Border = Theme.Border or Color3.fromRGB(34, 36, 48),
	BorderLight = Color3.fromRGB(50, 53, 70),
	Selected = Color3.fromRGB(35, 37, 49),
	Success = Theme.ToggleOn or Color3.fromRGB(52, 199, 89),
	Warning = Color3.fromRGB(254, 188, 46),
	Danger = Color3.fromRGB(255, 95, 87),
	AccentBlue = Color3.fromRGB(72, 138, 255),
}

local AccentA = Theme.Color.First
local AccentB = Theme.Color.Second
local library = {}
local activeLibrary

local function tween(object, duration, properties, style, direction)
	if not object or not object.Parent then return nil end
	local animation = TweenService:Create(object, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
	animation:Play()
	return animation
end

local function create(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	return create("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function outline(parent, transparency, color)
	return create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color or Palette.Border,
		Transparency = transparency == nil and 0.75 or transparency,
		Thickness = 1,
	}, parent)
end

local function gradient(parent, first, second)
	return create("UIGradient", {Color = ColorSequence.new(first or AccentA, second or AccentB), Rotation = 20}, parent)
end

local function surfaceGradient(parent, topColor, bottomColor)
	return create("UIGradient", {
		Color = ColorSequence.new(topColor, bottomColor),
		Rotation = 90,
	}, parent)
end

local function addPadding(parent, left, right, top, bottom)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
		PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0),
	}, parent)
end

local function addList(parent, padding, horizontal)
	return create("UIListLayout", {
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, padding or 0),
	}, parent)
end

local function safeCallback(callback, ...)
	if type(callback) ~= "function" then return true end
	local ok, result = pcall(callback, ...)
	if not ok then
		library.notification({Title = "Interface callback error", Desc = tostring(result), Type = 2})
	end
	return ok, result
end

local function guiParent()
	local target
	if type(gethui) == "function" then
		pcall(function() target = gethui() end)
	end
	return target or CoreGui
end

local function shorten(text, limit)
	text = tostring(text or "")
	if #text <= limit then return text end
	return string.sub(text, 1, math.max(1, limit - 1)) .. "…"
end

local function addHover(button, normal, hovered)
	button.AutoButtonColor = false
	button.Selectable = true
	button.MouseEnter:Connect(function() tween(button, 0.15, {BackgroundColor3 = hovered}) end)
	button.MouseLeave:Connect(function() tween(button, 0.15, {BackgroundColor3 = normal}) end)
end

local function createIcon(parent, asset, fallback, tint, size, position)
	local baseColor = tint or AccentA
	local shadedColor = Color3.new(baseColor.R * 0.76, baseColor.G * 0.76, baseColor.B * 0.82)
	local tile = create("Frame", {
		BackgroundColor3 = baseColor, BorderSizePixel = 0,
		Size = size or UDim2.fromOffset(26, 26), Position = position or UDim2.new(),
	}, parent)
	corner(tile, 7)
	gradient(tile, baseColor, shadedColor)
	outline(tile, 0.85, Color3.new(1, 1, 1))
	local hasAsset = (asset ~= nil and tostring(asset) ~= "")
	local image = create("ImageLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.65, 0.65),
		Image = hasAsset and tostring(asset) or "", ImageColor3 = Color3.new(1, 1, 1), ScaleType = Enum.ScaleType.Fit,
		Visible = hasAsset,
	}, tile)
	local symbol = create("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromScale(0.8, 0.8),
		Font = Enum.Font.GothamBold, Text = fallback or "•", TextColor3 = Color3.new(1, 1, 1),
		TextSize = (size and size.Y.Offset and size.Y.Offset > 30) and math.floor(size.Y.Offset * 0.44) or 12,
		Visible = not hasAsset,
	}, tile)
	create("UIAspectRatioConstraint", {AspectRatio = 1}, tile)
	return tile
end

local function notificationType(typeNumber)
	if typeNumber == 2 then return Palette.Danger, "!" end
	if typeNumber == 3 then return Palette.AccentBlue, "i" end
	return Palette.Success, "✓"
end

function library.notification(options)
	options = options or {}
	if not activeLibrary or not activeLibrary.NotificationHolder then return end
	local holder = activeLibrary.NotificationHolder
	local color, glyph = notificationType(options.Type)
	local toast = create("Frame", {
		BackgroundColor3 = Palette.Card, BorderSizePixel = 0, Size = UDim2.fromOffset(290, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = os.clock() * 1000,
	}, holder)
	corner(toast, 10)
	outline(toast, 0.72, Palette.BorderLight)
	local scale = create("UIScale", {Scale = 0.92}, toast)
	addPadding(toast, 10, 10, 10, 10)
	createIcon(toast, nil, glyph, color, UDim2.fromOffset(26, 26), UDim2.fromOffset(0, 0))
	create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -42, 0, 16),
		Font = Enum.Font.GothamBold, Text = tostring(options.Title or "Notification"), TextColor3 = Palette.Text,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, toast)
	create("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 16), Size = UDim2.new(1, -42, 0, 26),
		Font = Enum.Font.Gotham, Text = tostring(options.Desc or ""), TextColor3 = Palette.Muted,
		TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, toast)
	local bar = create("Frame", {BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 2)}, toast)
	corner(bar, 2)
	toast.Position = UDim2.fromOffset(320, 0)
	tween(toast, 0.25, {Position = UDim2.fromOffset(0, 0)})
	tween(scale, 0.25, {Scale = 1})
	tween(bar, 4.75, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
	task.delay(4.8, function()
		if not toast.Parent then return end
		local out = tween(toast, 0.2, {Position = UDim2.fromOffset(320, 0)})
		if out then out.Completed:Wait() end
		if toast.Parent then toast:Destroy() end
	end)
end

function library.create()
	local factory = {}

	function factory.Module()
		if activeLibrary and activeLibrary.Destroy then activeLibrary:Destroy() end
		local connections, sections, categoryFrames, records, configValues = {}, {}, {}, {}, {}
		local alive, minimized, maximized, collapsed = true, false, false, false
		local selectedSection, openedDropdown, openedDropdownArrow
		local responsiveScale = 1

		local function track(connection)
			table.insert(connections, connection)
			return connection
		end

		for _, child in ipairs(guiParent():GetChildren()) do
			if child.Name == "gamz.client" or child.Name == "gamz.client.open" or child.Name == "luxury.client" or child.Name == "seraph.client" or child.Name == "luxury.client.open" then
				pcall(function() child:Destroy() end)
			end
		end

		local screen = create("ScreenGui", {Name = "gamz.client", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())
		if type(protectgui) == "function" then pcall(protectgui, screen) end
		if type(syn) == "table" and type(syn.protect_gui) == "function" then pcall(syn.protect_gui, screen) end

		-- Soft outer shadow
		local shadow = create("ImageLabel", {
			Name = "Shadow",
			BackgroundTransparency = 1,
			Image = "rbxassetid://1316045217",
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.82,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(14, 14, 114, 114),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(812, 532),
			ZIndex = 0,
		}, screen)

		-- Main window container
		local window = create("Frame", {
			Name = "Window",
			BackgroundColor3 = Palette.Background,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(800, 520),
			ZIndex = 2,
		}, screen)

		corner(window, 12)
		outline(window, 0.65, Palette.BorderLight)
		surfaceGradient(window, Color3.fromRGB(20, 21, 28), Palette.Background)

		create("UISizeConstraint", {MinSize = Vector2.new(540, 360), MaxSize = Vector2.new(920, 620)}, window)
		local windowScale = create("UIScale", {Scale = 1}, window)

		local openGui = create("ScreenGui", {Name = "gamz.client.open", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, guiParent())
		if type(protectgui) == "function" then pcall(protectgui, openGui) end
		local opener = create("TextButton", {
			BackgroundColor3 = Palette.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 18, 1, -18),
			Size = UDim2.fromOffset(44, 44),
			Text = "X",
			TextColor3 = Palette.Text,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			Visible = false,
			AutoButtonColor = false,
		}, openGui)
		corner(opener, 22)
		outline(opener, 0.7, Palette.BorderLight)
		gradient(opener)

		-- Sleek sidebar
		local sidebar = create("Frame", {
			Name = "Sidebar",
			BackgroundColor3 = Palette.Sidebar,
			BorderSizePixel = 0,
			Size = UDim2.new(0.30, 0, 1, 0),
			ClipsDescendants = true,
		}, window)
		corner(sidebar, 12)
		surfaceGradient(sidebar, Color3.fromRGB(18, 19, 25), Palette.Sidebar)

		local content = create("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.30, 0, 0, 0),
			Size = UDim2.new(0.70, 0, 1, 0),
			ClipsDescendants = true,
		}, window)

		-- Sidebar Header (Logo + Title + Subtitle)
		local sideHeader = create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72), ZIndex = 2}, sidebar)
		local logo = createIcon(sideHeader, nil, "G", AccentA, UDim2.fromOffset(42, 42), UDim2.fromOffset(14, 14))
		corner(logo, 9)
		local hubTitle = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 16), Size = UDim2.new(1, -74, 0, 20),
			Font = Enum.Font.GothamBold, Text = "GAMZ Hub v0010", TextColor3 = Palette.Text, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, sideHeader)
		local hubSubtitle = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 36), Size = UDim2.new(1, -74, 0, 14),
			Font = Enum.Font.Gotham, Text = "Private Scripts", TextColor3 = Palette.Muted, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, sideHeader)

		-- Navigation List
		local navigation = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 68),
			Size = UDim2.new(1, -20, 1, -126), ScrollBarImageColor3 = Palette.Muted, ScrollBarImageTransparency = 0.5,
			ScrollBarThickness = 2, CanvasSize = UDim2.new(), Active = true, ZIndex = 2,
			ClipsDescendants = true, ScrollingDirection = Enum.ScrollingDirection.Y,
		}, sidebar)
		local navLayout = addList(navigation, 3)

		local function updateNavCanvas()
			local h = 0
			for _, cat in pairs(categoryFrames) do
				if cat.Frame and cat.Frame.Visible then
					h = h + cat.Frame.AbsoluteSize.Y + 3
				end
			end
			navigation.CanvasSize = UDim2.fromOffset(0, math.max(h + 8, navLayout.AbsoluteContentSize.Y + 8))
		end
		navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateNavCanvas)

		-- Profile Card at Bottom of Sidebar
		local profile = create("Frame", {
			BackgroundColor3 = Palette.Control,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -10),
			Size = UDim2.new(1, -20, 0, 44),
			ZIndex = 2,
		}, sidebar)
		corner(profile, 9)
		outline(profile, 0.75, Palette.BorderLight)
		surfaceGradient(profile, Color3.fromRGB(36, 38, 50), Palette.Control)

		local avatar = create("ImageLabel", {
			BackgroundColor3 = Palette.Card, BorderSizePixel = 0, Position = UDim2.fromOffset(7, 7),
			Size = UDim2.fromOffset(30, 30), Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
		}, profile)
		corner(avatar, 15)
		outline(avatar, 0.7, Palette.BorderLight)

		local username = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 8), Size = UDim2.new(1, -68, 0, 15),
			Font = Enum.Font.GothamBold, Text = "Player", TextColor3 = Palette.Text, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, profile)

		local userSub = create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 23), Size = UDim2.new(1, -68, 0, 13),
			Font = Enum.Font.Gotham, Text = "Local Player", TextColor3 = Palette.Muted, TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		}, profile)

		create("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(1, -24, 0, 14), Size = UDim2.fromOffset(16, 14),
			Font = Enum.Font.GothamBold, Text = "•••", TextColor3 = Palette.Subtle, TextSize = 9,
		}, profile)

		-- Topbar with Mac-style Traffic Light Buttons & Breadcrumb
		local topbar = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(16, 17, 22),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 44),
			ZIndex = 3,
		}, content)
		surfaceGradient(topbar, Color3.fromRGB(19, 20, 27), Color3.fromRGB(15, 16, 21))

		create("Frame", {
			BackgroundColor3 = Palette.Border,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
		}, topbar)

		-- Sidebar Toggle Icon Button
		local collapseButton = create("TextButton", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(10, 9),
			Size = UDim2.fromOffset(26, 26),
			Text = "",
			AutoButtonColor = false,
		}, topbar)
		corner(collapseButton, 8)
		local panelIcon = create("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 13),
		}, collapseButton)
		local panelStroke = outline(panelIcon, 0.18, Palette.Muted)
		corner(panelIcon, 3)
		local panelDivider = create("Frame", {
			BackgroundColor3 = Palette.Muted,
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(5, 1),
			Size = UDim2.fromOffset(1, 11),
		}, panelIcon)
		local panelSquareTop = create("Frame", {
			BackgroundColor3 = Palette.Muted,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, 3),
			Size = UDim2.fromOffset(2, 2),
		}, panelIcon)
		local panelSquareBottom = create("Frame", {
			BackgroundColor3 = Palette.Muted,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(2, 8),
			Size = UDim2.fromOffset(2, 2),
		}, panelIcon)

		collapseButton.MouseEnter:Connect(function()
			tween(collapseButton, 0.15, {BackgroundTransparency = 0.25, BackgroundColor3 = Palette.Control})
			tween(panelStroke, 0.15, {Color = Palette.Text})
			tween(panelDivider, 0.15, {BackgroundColor3 = Palette.Text})
			tween(panelSquareTop, 0.15, {BackgroundColor3 = Palette.Text})
			tween(panelSquareBottom, 0.15, {BackgroundColor3 = Palette.Text})
		end)
		collapseButton.MouseLeave:Connect(function()
			tween(collapseButton, 0.15, {BackgroundTransparency = 1})
			tween(panelStroke, 0.15, {Color = Palette.Muted})
			tween(panelDivider, 0.15, {BackgroundColor3 = Palette.Muted})
			tween(panelSquareTop, 0.15, {BackgroundColor3 = Palette.Muted})
			tween(panelSquareBottom, 0.15, {BackgroundColor3 = Palette.Muted})
		end)

		create("Frame", {
			BackgroundColor3 = Palette.Border,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(40, 13),
			Size = UDim2.fromOffset(1, 18),
		}, topbar)

		local breadcrumb = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(50, 0),
			Size = UDim2.new(1, -170, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = "Select a tab",
			TextColor3 = Palette.Muted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
		}, topbar)

		-- Mac-style Traffic Light Buttons (Red = Close, Yellow = Minimize, Green = Maximize)
		local function trafficButton(color, glyph, offset)
			local button = create("TextButton", {
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, offset, 0.5, 0),
				Size = UDim2.fromOffset(11, 11),
				Text = "",
				TextColor3 = Color3.fromRGB(35, 20, 20),
				Font = Enum.Font.GothamBold,
				TextSize = 8,
				AutoButtonColor = false,
			}, topbar)
			corner(button, 6)
			outline(button, 0.75, Color3.fromRGB(0, 0, 0))
			button.MouseEnter:Connect(function()
				button.Text = glyph
				tween(button, 0.15, {Size = UDim2.fromOffset(12, 12)})
			end)
			button.MouseLeave:Connect(function()
				button.Text = ""
				tween(button, 0.15, {Size = UDim2.fromOffset(11, 11)})
			end)
			return button
		end

		local closeButton = trafficButton(Palette.Danger, "×", -52)
		local minimizeButton = trafficButton(Palette.Warning, "−", -34)
		local maximizeButton = trafficButton(Palette.Success, "+", -16)

		local body = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44), ClipsDescendants = true}, content)
		local notifications = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(300, 380), ZIndex = 100}, screen)
		local notifyList = addList(notifications, 8)
		notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom

		local Main = {ScreenGui = screen, Window = window, NotificationHolder = notifications}
		activeLibrary = Main

		local function bindPress(button, callback)
			local lastPress = 0
			local function fire()
				local now = os.clock()
				if now - lastPress < 0.12 then return end
				lastPress = now
				callback()
			end
			track(button.Activated:Connect(fire))
			track(button.MouseButton1Click:Connect(fire))
		end

		local function resizeForViewport()
			local camera = workspace.CurrentCamera
			if not camera then return end
			local viewport = camera.ViewportSize
			responsiveScale = math.clamp(math.min(viewport.X / 880, viewport.Y / 560), 0.7, 1)
			windowScale.Scale = responsiveScale
			shadow.Size = UDim2.fromOffset(792 * responsiveScale, 482 * responsiveScale)
		end
		if workspace.CurrentCamera then track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeForViewport)) end
		resizeForViewport()

		local function setWindowVisible(visible)
			minimized = not visible
			if visible then
				window.Visible, shadow.Visible, opener.Visible = true, true, false
				windowScale.Scale = responsiveScale * 0.94
				tween(windowScale, 0.2, {Scale = responsiveScale}, Enum.EasingStyle.Quint)
			else
				local out = tween(windowScale, 0.16, {Scale = responsiveScale * 0.9}, Enum.EasingStyle.Quad)
				task.spawn(function()
					if out then out.Completed:Wait() end
					if alive and minimized then window.Visible, shadow.Visible, opener.Visible = false, false, true end
				end)
			end
		end

		local function setSidebar(isCollapsed)
			collapsed = isCollapsed
			local sideWidth = collapsed and 0.11 or 0.30
			tween(sidebar, 0.22, {Size = UDim2.new(sideWidth, 0, 1, 0)}, Enum.EasingStyle.Quint)
			tween(content, 0.22, {Position = UDim2.new(sideWidth, 0, 0, 0), Size = UDim2.new(1 - sideWidth, 0, 1, 0)}, Enum.EasingStyle.Quint)
			hubTitle.Visible, hubSubtitle.Visible, profile.Visible = not collapsed, not collapsed, not collapsed
			navigation.Position = collapsed and UDim2.fromOffset(0, 62) or UDim2.fromOffset(10, 68)
			navigation.Size = collapsed and UDim2.new(1, 0, 1, -74) or UDim2.new(1, -20, 1, -126)
			-- Center logo when collapsed
			if collapsed then
				tween(logo, 0.22, {Position = UDim2.new(0.5, -21, 0, 14)}, Enum.EasingStyle.Quint)
				sideHeader.Size = UDim2.new(1, 0, 0, 60)
			else
				tween(logo, 0.22, {Position = UDim2.fromOffset(14, 14)}, Enum.EasingStyle.Quint)
				sideHeader.Size = UDim2.new(1, 0, 0, 72)
			end
			for _, category in pairs(categoryFrames) do
				if category.Label then
					category.Label.Visible = not collapsed
				end
			end
			for _, section in ipairs(sections) do
				section.Title.Visible = not collapsed
				local iconFrame = section.Button:FindFirstChild("Frame") or section.Button:FindFirstChildWhichIsA("Frame")
				if collapsed then
					tween(section.Button, 0.22, {Size = UDim2.fromOffset(36, 36)}, Enum.EasingStyle.Quint)
					if iconFrame then
						iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
						tween(iconFrame, 0.22, {Position = UDim2.new(0.5, 0, 0.5, 0)}, Enum.EasingStyle.Quint)
					end
				else
					tween(section.Button, 0.22, {Size = UDim2.new(1, 0, 0, 36)}, Enum.EasingStyle.Quint)
					if iconFrame then
						iconFrame.AnchorPoint = Vector2.new(0, 0)
						tween(iconFrame, 0.22, {Position = UDim2.fromOffset(6, 5)}, Enum.EasingStyle.Quint)
					end
				end
			end
			updateNavCanvas()
		end

		local function selectSection(section)
			if not section or not alive then return end
			selectedSection = section
			for _, other in ipairs(sections) do
				other.Canvas.Visible = other == section
				local selected = other == section
				if selected then
					tween(other.Button, 0.18, {BackgroundColor3 = Palette.Selected, BackgroundTransparency = 0})
				else
					tween(other.Button, 0.18, {BackgroundTransparency = 1})
				end
				other.Title.TextColor3 = selected and Palette.Text or Palette.Muted
				other.Title.Font = selected and Enum.Font.GothamBold or Enum.Font.GothamMedium
			end
			breadcrumb.Text = '<font color="rgb(138, 142, 160)">' .. section.Category .. '</font>  <font color="rgb(85, 88, 105)">›</font>  <font color="rgb(242, 244, 250)">' .. section.Name .. '</font>'
		end

		-- Modal shield for dropdown click-outside closing
		local modalShield = create("TextButton", {
			Name = "ModalShield",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 29,
			Visible = false,
		}, window)

		local function closeDropdown()
			if not openedDropdown then modalShield.Visible = false; return end
			local popup = openedDropdown
			if openedDropdownArrow then
				openedDropdownArrow.Text = "v"
				openedDropdownArrow = nil
			end
			openedDropdown = nil
			modalShield.Visible = false
			local closeTween = tween(popup, 0.16, {Size = UDim2.fromOffset(0, 0)})
			task.spawn(function()
				if closeTween then closeTween.Completed:Wait() end
				if popup.Parent and openedDropdown ~= popup then popup.Visible = false end
			end)
		end

		bindPress(modalShield, function() closeDropdown() end)

		local function makeRow(group, options, kind)
			options = options or {}
			local index = #group.Records
			local row = create("Frame", {Name = kind .. "Row", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 50), LayoutOrder = index}, group.Card)
			if index > 0 then
				create("Frame", {
					BackgroundColor3 = Palette.Border,
					BackgroundTransparency = 0.88,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 14, 0, 0),
					Size = UDim2.new(1, -28, 0, 1),
				}, row)
			end

			local hasDesc = (options.Description and options.Description ~= "") or (options.Desc and options.Desc ~= "")
			local titleY = hasDesc and 8 or 16

			local title = create("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(14, titleY), Size = UDim2.new(0.55, 0, 0, 16),
				Font = Enum.Font.GothamMedium, Text = tostring(options.Title or kind), TextColor3 = Palette.Text,
				TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, row)

			local desc
			if hasDesc then
				desc = create("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 25), Size = UDim2.new(0.58, 0, 0, 16),
					Font = Enum.Font.Gotham, Text = tostring(options.Description or options.Desc or ""), TextColor3 = Palette.Muted,
					TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
			end

			local record = {Row = row, Text = tostring(options.Title or kind) .. " " .. tostring(options.Description or options.Desc or ""), Section = group.Section}
			table.insert(group.Records, record)
			table.insert(records, record)
			return row, title, desc
		end

		local function registerConfig(options, set, get)
			if options and options.Flag then configValues[options.Flag] = {Set = set, Get = get} end
		end

		local function createGroup(section, options)
			options = options or {}
			local group = {Section = section, Records = {}}
			local container = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, section.Canvas)
			group.Container = container
			addList(container, 6)

			-- Group Header (Squircle Icon + Title + Subtitle)
			local heading = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42)}, container)
			local headIcon = createIcon(heading, options.Icon, string.sub(tostring(options.Title or section.Name), 1, 1), options.IconColor or AccentA, UDim2.fromOffset(28, 28), UDim2.fromOffset(2, 7))
			corner(headIcon, 7)
			create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(38, 5), Size = UDim2.new(1, -42, 0, 17), Font = Enum.Font.GothamBold, Text = tostring(options.Title or section.Name), TextColor3 = Palette.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, heading)
			create("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(38, 22), Size = UDim2.new(1, -42, 0, 15), Font = Enum.Font.Gotham, Text = tostring(options.Description or ""), TextColor3 = Palette.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, heading)

			local card = create("Frame", {BackgroundColor3 = Palette.Card, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, container)
			corner(card, 10)
			outline(card, 0.72, Palette.CardBorder)
			surfaceGradient(card, Color3.fromRGB(26, 27, 35), Palette.Card)
			addPadding(card, 0, 0, 2, 2)
			addList(card, 0)
			group.Card = card

			local page = {}

			function page.Button(component)
				component = component or {}
				local callback = component.callback or component.Callback
				local row = makeRow(group, component, "Button")
				local button = create("TextButton", {
					BackgroundColor3 = AccentA, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(100, 28),
					Text = "", AutoButtonColor = false,
				}, row)
				corner(button, 7)
				gradient(button)
				outline(button, 0.88, Color3.fromRGB(255, 255, 255))

				local btnText = create("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
					Text = tostring(component.ButtonText or "Run"), TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11, Font = Enum.Font.GothamBold,
				}, button)

				button.MouseEnter:Connect(function() tween(button, 0.15, {Size = UDim2.fromOffset(103, 29)}) end)
				button.MouseLeave:Connect(function() tween(button, 0.15, {Size = UDim2.fromOffset(100, 28)}) end)
				button.MouseButton1Down:Connect(function() tween(button, 0.08, {Size = UDim2.fromOffset(96, 26)}) end)
				button.MouseButton1Up:Connect(function() tween(button, 0.12, {Size = UDim2.fromOffset(100, 28)}) end)
				bindPress(button, function() safeCallback(callback) end)
				return {Options = function() return button end}
			end

			function page.Label(component)
				component = component or {}
				local row, title = makeRow(group, component, "Label")
				local value = create("TextLabel", {
					BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0.36, 0, 0, 20),
					Font = Enum.Font.GothamMedium, Text = tostring(component.Value or component.Text or ""),
					TextColor3 = Palette.Muted, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local api = {}
				function api.UpdateColor(first, second) tween(title, 0.15, {TextColor3 = second or first}) end
				function api.Options() return title end
				function api.SetText(first, second) value.Text = tostring(second or first or "") end
				return api
			end

			function page.Status(component)
				return page.Label(component)
			end

			function page.Toggle(component)
				component = component or {}
				local callback = component.callback or component.Callback
				local row = makeRow(group, component, "Toggle")
				local trackFrame = create("Frame", {
					BackgroundColor3 = Palette.Control, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(38, 20),
				}, row)
				corner(trackFrame, 10)
				local trackStroke = outline(trackFrame, 0.84, Palette.Border)
				local knob = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(3, 10),
					Size = UDim2.fromOffset(14, 14),
				}, trackFrame)
				corner(knob, 7)
				outline(knob, 0.8, Color3.fromRGB(0, 0, 0))
				local hitbox = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false}, trackFrame)
				local state, locked = false, false
				local function set(value, call)
					state = value and true or false
					tween(trackFrame, 0.2, {BackgroundColor3 = state and Palette.Success or Palette.Control}, Enum.EasingStyle.Quart)
					tween(trackStroke, 0.2, {Transparency = state and 0.9 or 0.84})
					tween(knob, 0.2, {Position = state and UDim2.fromOffset(21, 10) or UDim2.fromOffset(3, 10)}, Enum.EasingStyle.Quart)
					if call then safeCallback(callback, state) end
				end
				bindPress(hitbox, function() if not locked then set(not state, true) end end)
				local api = {}
				function api.SetValue(first, second) set(second == nil and first or second, true) end
				function api.Lock() locked = true; hitbox.Active = false; tween(trackFrame, 0.15, {BackgroundTransparency = 0.45}) end
				function api.Unlock() locked = false; hitbox.Active = true; tween(trackFrame, 0.15, {BackgroundTransparency = 0}) end
				function api.GetValue() return state end
				set(component.Default == true or component.default == true, false)
				registerConfig(component, function(value) set(value, true) end, function() return state end)
				return api
			end

			function page.Slider(component)
				component = component or {}
				local callback = component.callback or component.Callback
				local row = makeRow(group, component, "Slider")
				local minimum, maximum = tonumber(component.Min) or 0, tonumber(component.Max) or 100
				if maximum <= minimum then maximum = minimum + 1 end
				local decimal = component.Dec == true
				local suffix = component.Type and (" " .. tostring(component.Type)) or ""
				local bar = create("Frame", {BackgroundColor3 = Palette.Control, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(130, 5)}, row)
				corner(bar, 3)
				outline(bar, 0.88, Palette.Border)
				local fill = create("Frame", {BackgroundColor3 = AccentA, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0)}, bar)
				corner(fill, 3); gradient(fill)
				local handle = create("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(13, 13)}, bar)
				corner(handle, 7)
				outline(handle, 0.75, Color3.fromRGB(0, 0, 0))

				local input = create("TextBox", {
					BackgroundTransparency = 1, ClearTextOnFocus = false, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -152, 0.5, 0), Size = UDim2.fromOffset(50, 18),
					Font = Enum.Font.GothamBold, TextColor3 = Palette.Muted, TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Right, Text = "",
				}, row)

				local hitbox = create("TextButton", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 14, 1, 18), Position = UDim2.fromOffset(-7, -9), Text = "", AutoButtonColor = false}, bar)
				local value, dragging = minimum, false
				local function set(newValue, call)
					newValue = math.clamp(tonumber(newValue) or minimum, minimum, maximum)
					if not decimal then newValue = math.floor(newValue + 0.5) end
					value = newValue
					local alpha = (value - minimum) / (maximum - minimum)
					tween(fill, 0.15, {Size = UDim2.new(alpha, 0, 1, 0)})
					tween(handle, 0.15, {Position = UDim2.new(alpha, 0, 0.5, 0)})
					input.Text = (decimal and string.format("%.2f", value) or tostring(value)) .. suffix
					if call then safeCallback(callback, value) end
				end
				local function setFromPosition(position)
					if bar.AbsoluteSize.X <= 0 then return end
					set(minimum + math.clamp((position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * (maximum - minimum), true)
				end
				track(hitbox.InputBegan:Connect(function(inputObject)
					if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromPosition(inputObject.Position) end
				end))
				track(UserInputService.InputChanged:Connect(function(inputObject)
					if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then setFromPosition(inputObject.Position) end
				end))
				track(UserInputService.InputEnded:Connect(function(inputObject)
					if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then dragging = false end
				end))
				track(input.FocusLost:Connect(function(entered)
					if entered then
						local parsed = tonumber(string.match(input.Text or "", "[-%d%.]+"))
						set(parsed or value, true)
					else
						set(value, false)
					end
				end))
				local api = {}
				function api.Update(first, second) set(second == nil and first or second, true) end
				function api.SetValue(val) set(val, true) end
				set(component.Default or component.default or minimum, false)
				registerConfig(component, function(newValue) set(newValue, true) end, function() return value end)
				return api
			end

			function page.Textbox(component)
				component = component or {}
				local callback = component.callback or component.Callback
				local row = makeRow(group, {Title = component.Title or component.name or "Textbox", Description = component.Description or component.Desc}, "Textbox")
				local box = create("TextBox", {
					BackgroundColor3 = Palette.Control, BorderSizePixel = 0, ClearTextOnFocus = false,
					PlaceholderText = tostring(component.Placeholder or component.name or "Enter text"),
					PlaceholderColor3 = Palette.Subtle, Text = tostring(component.Default or ""),
					TextColor3 = Palette.Text, TextSize = 11, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(145, 28),
				}, row)
				corner(box, 7)
				local boxStroke = outline(box, 0.72, Palette.BorderLight)
				surfaceGradient(box, Color3.fromRGB(36, 38, 50), Palette.Control)
				addPadding(box, 8, 6, 0, 0)
				box.Focused:Connect(function()
					tween(boxStroke, 0.18, {Transparency = 0.3, Color = AccentA})
				end)
				box.FocusLost:Connect(function(entered)
					tween(boxStroke, 0.18, {Transparency = 0.78, Color = Palette.Border})
					if entered then safeCallback(callback, box.Text) end
				end)
				local api = {}
				function api.SetText(first, second) box.Text = tostring(second or first or "") end
				function api.Options() return box end
				registerConfig(component, function(value) box.Text = tostring(value or "") end, function() return box.Text end)
				return api
			end

			function page.Dropdown(component)
				component = component or {}
				local callback = component.callback or component.Callback
				local isMulti = component.multi == true
				local row = makeRow(group, component, "Dropdown")
				local label = create("TextButton", {
					BackgroundColor3 = Palette.Control, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(isMulti and 165 or 150, 28), Text = "", AutoButtonColor = false,
				}, row)
				corner(label, 7)
				outline(label, 0.72, Palette.BorderLight)
				surfaceGradient(label, Color3.fromRGB(36, 38, 50), Palette.Control)
				addHover(label, Palette.Control, Palette.ControlHover)

				local current = create("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
					Size = isMulti and UDim2.new(1, -54, 1, 0) or UDim2.new(1, -26, 1, 0),
					Font = Enum.Font.GothamMedium, Text = tostring(component.Title or "Select"), TextColor3 = Palette.Text,
					TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				}, label)

				local badge, clearBtn
				if isMulti then
					badge = create("TextLabel", {
						BackgroundColor3 = Palette.ControlHover, BorderSizePixel = 0,
						AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0),
						Size = UDim2.fromOffset(20, 16), Font = Enum.Font.GothamBold,
						Text = "0", TextColor3 = Palette.Muted, TextSize = 9,
					}, label)
					corner(badge, 4)

					clearBtn = create("TextButton", {
						BackgroundTransparency = 1, BorderSizePixel = 0,
						AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
						Size = UDim2.fromOffset(14, 16), Font = Enum.Font.GothamBold,
						Text = "×", TextColor3 = Palette.Muted, TextSize = 10, AutoButtonColor = false,
					}, label)
				end

				local arrow = create("TextLabel", {
					BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(12, 16),
					Font = Enum.Font.GothamBold, Text = "v", TextColor3 = Palette.Muted, TextSize = 9,
				}, label)

				local popup = create("Frame", {BackgroundColor3 = Palette.Card, BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Size = UDim2.fromOffset(0, 0), ZIndex = 30}, window)
				corner(popup, 9)
				outline(popup, 0.62, Palette.BorderLight)
				surfaceGradient(popup, Color3.fromRGB(30, 31, 40), Palette.Card)

				create("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 16),
					ZIndex = 31, Font = Enum.Font.GothamBold, Text = tostring(component.Title or "Select"),
					TextColor3 = Palette.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				}, popup)

				local filter = create("TextBox", {
					BackgroundColor3 = Palette.Control, BorderSizePixel = 0, ClearTextOnFocus = false,
					PlaceholderText = "Search…", PlaceholderColor3 = Palette.Muted, Text = "",
					TextColor3 = Palette.Text, TextSize = 10, Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(8, 25), Size = UDim2.new(1, -16, 0, 24), ZIndex = 31,
				}, popup)
				corner(filter, 6)
				addPadding(filter, 6, 4, 0, 0)
				outline(filter, 0.75, Palette.BorderLight)

				local choices = create("ScrollingFrame", {
					BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 53),
					Size = UDim2.new(1, -12, 1, -58), ScrollBarThickness = 2, ScrollBarImageColor3 = Palette.Muted,
					ScrollBarImageTransparency = 0.75, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 31,
				}, popup)
				addPadding(choices, 2, 2, 0, 4)
				addList(choices, 3)

				local items, buttons, selected = {}, {}, isMulti and {} or nil

				local function isSelected(item)
					if isMulti then return selected[item] == true end
					return selected == item
				end

				local function countSelected()
					if not isMulti then return selected and 1 or 0 end
					local count = 0
					for _, item in ipairs(items) do
						if selected[item] then count = count + 1 end
					end
					return count
				end

				local function selectedText()
					if isMulti then
						local result = {}
						for _, item in ipairs(items) do
							if selected[item] then table.insert(result, tostring(item)) end
						end
						return #result > 0 and table.concat(result, ", ") or tostring(component.Title or "Select")
					end
					return selected and tostring(selected) or tostring(component.Title or "Select")
				end

				local function fire()
					current.Text = selectedText()
					if isMulti and badge then
						local c = countSelected()
						badge.Text = tostring(c)
						badge.TextColor3 = c > 0 and Palette.Text or Palette.Muted
						badge.BackgroundColor3 = c > 0 and Palette.Selected or Palette.ControlHover
					end
					if isMulti then
						local result = {}
						for _, item in ipairs(items) do
							if selected[item] then table.insert(result, item) end
						end
						safeCallback(callback, result)
					else
						safeCallback(callback, selected)
					end
				end

				local function redraw()
					for item, data in pairs(buttons) do
						local checked = isSelected(item)
						data.Check.Text = checked and "✓" or ""
						data.Check.BackgroundColor3 = checked and AccentA or Palette.Control
						data.Name.TextColor3 = checked and Palette.Text or Palette.Muted
					end
					if isMulti and badge then
						local c = countSelected()
						badge.Text = tostring(c)
						badge.TextColor3 = c > 0 and Palette.Text or Palette.Muted
					end
				end

				local function addItem(item)
					if item == nil or buttons[item] then return end
					table.insert(items, item)
					local button = create("TextButton", {
						BackgroundColor3 = Palette.Control, BackgroundTransparency = 0.45,
						BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28), Text = "", AutoButtonColor = false, ZIndex = 32,
					}, choices)
					corner(button, 6)
					addHover(button, Palette.Control, Palette.ControlHover)

					local itemName = create("TextLabel", {
						BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -34, 1, 0),
						ZIndex = 33, Font = Enum.Font.Gotham, Text = tostring(item), TextColor3 = Palette.Text,
						TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					}, button)

					local check = create("TextLabel", {
						BackgroundColor3 = Palette.Control, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(14, 14), ZIndex = 33,
						Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.new(1, 1, 1), TextSize = 9,
					}, button)
					corner(check, 4)
					buttons[item] = {Button = button, Name = itemName, Check = check}

					bindPress(button, function()
						if isMulti then
							selected[item] = not selected[item]
						else
							selected = item
							closeDropdown()
						end
						redraw()
						fire()
					end)
				end

				local function clearItems()
					for _, data in pairs(buttons) do data.Button:Destroy() end
					items, buttons, selected = {}, {}, isMulti and {} or nil
					current.Text = tostring(component.Title or "Select")
					if isMulti and badge then badge.Text = "0" end
				end

				local function setDefault(value)
					if isMulti then
						if type(value) == "table" then
							for _, item in ipairs(value) do selected[item] = true end
						end
					elseif value ~= nil then
						selected = value
					end
					redraw()
					current.Text = selectedText()
					if isMulti and badge then badge.Text = tostring(countSelected()) end
				end

				for _, item in ipairs(component.item or component.Item or {}) do addItem(item) end
				setDefault(component.default or component.Default)

				if isMulti and clearBtn then
					bindPress(clearBtn, function()
						selected = {}
						redraw()
						fire()
					end)
				end

				track(filter:GetPropertyChangedSignal("Text"):Connect(function()
					local query = string.lower(filter.Text)
					for item, data in pairs(buttons) do
						data.Button.Visible = query == "" or string.find(string.lower(tostring(item)), query, 1, true) ~= nil
					end
				end))

				bindPress(label, function()
					if openedDropdown == popup then closeDropdown(); return end
					closeDropdown()
					openedDropdown = popup
					openedDropdownArrow = arrow
					popup.Visible = true
					arrow.Text = "^"
					modalShield.Visible = true
					local relative = label.AbsolutePosition - window.AbsolutePosition
					local desiredWidth, desiredHeight = 240, math.min(220, 64 + math.max(#items, 1) * 30)
					local x = math.clamp(relative.X + label.AbsoluteSize.X - desiredWidth, 8, math.max(8, window.AbsoluteSize.X - desiredWidth - 8))
					local yBelow = relative.Y + label.AbsoluteSize.Y + 4
					local y
					if yBelow + desiredHeight > window.AbsoluteSize.Y - 10 then
						y = math.max(8, relative.Y - desiredHeight - 4)
					else
						y = yBelow
					end
					popup.Position = UDim2.fromOffset(x, y)
					tween(popup, 0.18, {Size = UDim2.fromOffset(desiredWidth, desiredHeight)}, Enum.EasingStyle.Quint)
				end)

				local api = {}
				function api.Clear() clearItems() end
				function api.Add(first, second)
					local data = second or first
					if type(data) == "table" then for _, item in ipairs(data) do addItem(item) end else addItem(data) end
					redraw()
				end
				function api.Options(first, second)
					local value = second
					if value == nil and type(first) ~= "table" and first ~= api then value = first end
					if value == false then current.Text = tostring(component.Title or "Select") end
					return current
				end
				function api.Set(val) setDefault(val) end
				function api.SetValue(val) setDefault(val) end
				function api.GetValue()
					if isMulti then
						local result = {}
						for _, item in ipairs(items) do if selected[item] then table.insert(result, item) end end
						return result
					end
					return selected
				end
				return api
			end

			-- ItemList / Entity / Boss / Status Table Component
			function page.ItemList(component)
				component = component or {}
				local listContainer = create("Frame", {
					Name = "ItemListContainer",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = #group.Records + 1,
				}, group.Card)
				addList(listContainer, 0)

				local itemEntries = {}

				local function createItemRow(data, index)
					local row = create("Frame", {
						Name = "ItemRow",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 32),
						LayoutOrder = index or #itemEntries + 1,
					}, listContainer)

					-- Row separator line
					create("Frame", {
						BackgroundColor3 = Palette.Border,
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 14, 0, 0),
						Size = UDim2.new(1, -28, 0, 1),
					}, row)

					-- Small thumbnail icon
					local icon = create("ImageLabel", {
						BackgroundColor3 = Palette.Control,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset(14, 6),
						Size = UDim2.fromOffset(20, 20),
						Image = data.Icon or "rbxasset://textures/ui/GuiImagePlaceholder.png",
						ImageColor3 = Color3.fromRGB(240, 240, 240),
					}, row)
					corner(icon, 5)
					outline(icon, 0.8, Palette.BorderLight)

					-- Item Name
					local nameLabel = create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(42, 0),
						Size = UDim2.new(0.65, -42, 1, 0),
						Font = Enum.Font.GothamMedium,
						Text = tostring(data.Name or "Item"),
						TextColor3 = Palette.Text,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}, row)

					-- Status Label (Countdown time or Spawned status)
					local isSpawned = data.Spawned == true or (data.Status and string.find(tostring(data.Status), "Spawned") ~= nil)
					local statusLabel = create("TextLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -14, 0.5, 0),
						Size = UDim2.new(0.32, 0, 0, 20),
						Font = isSpawned and Enum.Font.GothamBold or Enum.Font.GothamMedium,
						Text = tostring(data.Status or (isSpawned and "✓ Spawned" or "")),
						TextColor3 = isSpawned and Palette.AccentBlue or Palette.Muted,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, row)

					row.MouseEnter:Connect(function()
						tween(row, 0.12, {BackgroundTransparency = 0.65, BackgroundColor3 = Palette.ControlHover})
					end)
					row.MouseLeave:Connect(function()
						tween(row, 0.12, {BackgroundTransparency = 1})
					end)

					return {
						Row = row,
						NameLabel = nameLabel,
						StatusLabel = statusLabel,
						Icon = icon,
						Data = data,
					}
				end

				for i, itemData in ipairs(component.Items or component.items or {}) do
					itemEntries[itemData.Name or tostring(i)] = createItemRow(itemData, i)
				end

				local api = {}

				function api.UpdateStatus(name, newStatus, spawned, optionalColor)
					local entry = itemEntries[name]
					if entry then
						entry.Data.Status = newStatus
						entry.Data.Spawned = spawned
						entry.StatusLabel.Text = tostring(newStatus)
						local isSpawned = spawned == true or string.find(tostring(newStatus), "Spawned") ~= nil
						if isSpawned then
							entry.StatusLabel.TextColor3 = optionalColor or Palette.AccentBlue
							entry.StatusLabel.Font = Enum.Font.GothamBold
						else
							entry.StatusLabel.TextColor3 = optionalColor or Palette.Muted
							entry.StatusLabel.Font = Enum.Font.GothamMedium
						end
					end
				end

				function api.AddItem(itemData)
					if not itemData or not itemData.Name then return end
					if itemEntries[itemData.Name] then
						api.UpdateStatus(itemData.Name, itemData.Status, itemData.Spawned)
						return
					end
					itemEntries[itemData.Name] = createItemRow(itemData)
				end

				function api.RemoveItem(name)
					local entry = itemEntries[name]
					if entry then
						entry.Row:Destroy()
						itemEntries[name] = nil
					end
				end

				function api.Clear()
					for _, entry in pairs(itemEntries) do
						entry.Row:Destroy()
					end
					itemEntries = {}
				end

				function api.SetItems(newItems)
					api.Clear()
					for i, itemData in ipairs(newItems or {}) do
						itemEntries[itemData.Name or tostring(i)] = createItemRow(itemData, i)
					end
				end

				return api
			end

			-- Aliases for convenience
			page.BossList = page.ItemList
			page.StatusList = page.ItemList
			page.EntityList = page.ItemList

			table.insert(section.Groups, group)
			return page
		end

		function Main.section(options)
			options = options or {}
			local section = {Name = tostring(options.Title or "Tab"), Category = tostring(options.Category or "General"), Groups = {}}
			local category = categoryFrames[section.Category]
			if not category then
				local frame = create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, navigation)
				local catList = addList(frame, 3)
				catList.HorizontalAlignment = Enum.HorizontalAlignment.Center
				local categoryLabel = create("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold,
					Text = section.Category, TextColor3 = Palette.Subtle, TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, frame)
				addPadding(categoryLabel, 6, 0, 6, 2)
				category = {Frame = frame, Label = categoryLabel}
				categoryFrames[section.Category] = category
				frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateNavCanvas)
			end

			local item = create("TextButton", {
				BackgroundColor3 = Palette.Selected, BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = collapsed and UDim2.fromOffset(36, 36) or UDim2.new(1, 0, 0, 36), Text = "", AutoButtonColor = false,
			}, category.Frame)
			corner(item, 8)

			local iconColor = options.IconColor or AccentA
			local iconFrame = createIcon(item, options.Icon, string.sub(section.Name, 1, 1), iconColor, UDim2.fromOffset(26, 26), collapsed and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(6, 5))
			if collapsed then
				iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			end

			local itemTitle = create("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0),
				Font = Enum.Font.GothamMedium, Text = section.Name, TextColor3 = Palette.Muted,
				TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				Visible = not collapsed,
			}, item)

			local canvas = create("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0),
				Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = Palette.Muted,
				ScrollBarImageTransparency = 0.75, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
				Visible = false, Active = true,
			}, body)
			addPadding(canvas, 14, 14, 12, 16)
			addList(canvas, 12)

			track(canvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				if openedDropdown then closeDropdown() end
			end))

			section.Button, section.Title, section.Canvas, section.CategoryLabel = item, itemTitle, canvas, category.Label
			bindPress(item, function() selectSection(section) end)

			track(item.MouseEnter:Connect(function()
				if selectedSection ~= section then
					tween(item, 0.15, {BackgroundTransparency = 0.65, BackgroundColor3 = Palette.Control})
				end
			end))
			track(item.MouseLeave:Connect(function()
				if selectedSection ~= section then
					tween(item, 0.15, {BackgroundTransparency = 1})
				else
					tween(item, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = Palette.Selected})
				end
			end))

			table.insert(sections, section)
			if #sections == 1 then selectSection(section) end
			updateNavCanvas()

			local api = {}
			function api.page(pageOptions) return createGroup(section, pageOptions) end
			return api
		end

		function Main.SetTitle(first, second, third)
			local title, subtitle
			if first == Main then title, subtitle = second, third else title, subtitle = first, second end
			if title then hubTitle.Text = tostring(title) end
			if subtitle then hubSubtitle.Text = tostring(subtitle) end
		end

		function Main.SetLogoBackground(first, second, third)
			local primary, secondary
			if first == Main then primary, secondary = second, third else primary, secondary = first, second end
			if typeof(primary) ~= "Color3" then return end
			logo.BackgroundTransparency = 0
			logo.BackgroundColor3 = primary
			local darker = secondary
			if typeof(darker) ~= "Color3" then darker = Color3.new(primary.R * 0.66, primary.G * 0.66, primary.B * 0.78) end
			for _, object in ipairs(logo:GetChildren()) do
				if object:IsA("UIGradient") then object.Enabled = true; object.Color = ColorSequence.new(primary, darker) end
			end
		end

		function Main.SetLogo(first, second)
			local image = first == Main and second or first
			logo.BackgroundTransparency = 1
			logo.Size = UDim2.fromOffset(46, 46)
			for _, object in ipairs(logo:GetChildren()) do
				if object:IsA("UIGradient") then object.Enabled = false end
				if object:IsA("UIStroke") then object.Enabled = false end
			end
			if type(image) == "string" and image ~= "" then
				local iconImage, fallbackText
				for _, object in ipairs(logo:GetChildren()) do
					if object:IsA("ImageLabel") then
						iconImage = object
						object.Image = image
						object.Size = UDim2.new(1, 0, 1, 0)
						object.Position = UDim2.fromScale(0.5, 0.5)
						object.ScaleType = Enum.ScaleType.Fit
						object.Visible = true
					end
					if object:IsA("TextLabel") then fallbackText = object; object.Visible = false end
				end
				if iconImage and fallbackText then
					track(iconImage:GetPropertyChangedSignal("IsLoaded"):Connect(function()
						if fallbackText.Parent then fallbackText.Visible = not iconImage.IsLoaded end
					end))
					task.delay(2, function()
						if iconImage.Parent and fallbackText.Parent then fallbackText.Visible = not iconImage.IsLoaded end
					end)
				end
			end
		end

		function Main.SetUser(first, second)
			local data = first == Main and second or first or {}
			if type(data) == "string" then username.Text = data; return end
			local rawName = data.Name or data.Username or (LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name)) or "Player"
			if data.Masked or data.Mask == true then
				if #rawName > 4 then
					rawName = string.sub(rawName, 1, 2) .. string.rep("*", math.max(6, #rawName - 4)) .. string.sub(rawName, -2)
				else
					rawName = string.rep("*", #rawName)
				end
			end
			username.Text = rawName
			userSub.Text = tostring(data.Subtitle or data.Status or (LocalPlayer and ("@" .. LocalPlayer.Name)) or "Local Player")
			if type(data.Image) == "string" then avatar.Image = data.Image end
		end

		function Main.SaveConfig(first, second)
			local fileName = second or first or "gamz_config.json"
			if type(writefile) ~= "function" then return false, "writefile is unavailable" end
			local values = {}
			for flag, entry in pairs(configValues) do values[flag] = entry.Get() end
			local ok, encoded = pcall(HttpService.JSONEncode, HttpService, values)
			if not ok then return false, encoded end
			return pcall(writefile, fileName, encoded)
		end

		function Main.LoadConfig(first, second)
			local fileName = second or first or "gamz_config.json"
			if type(readfile) ~= "function" then return false, "readfile is unavailable" end
			if type(isfile) == "function" then
				local exists = false
				pcall(function() exists = isfile(fileName) end)
				if not exists then return false, "config does not exist" end
			end
			local ok, content = pcall(readfile, fileName)
			if not ok then return false, content end
			local decodedOk, values = pcall(HttpService.JSONDecode, HttpService, content)
			if not decodedOk or type(values) ~= "table" then return false, values end
			for flag, value in pairs(values) do if configValues[flag] then configValues[flag].Set(value) end end
			return true
		end

		function Main.Destroy(self)
			if not alive then return end
			alive = false
			closeDropdown()
			for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
			pcall(function() openGui:Destroy() end)
			pcall(function() screen:Destroy() end)
			if activeLibrary == Main then activeLibrary = nil end
		end

		bindPress(collapseButton, function() setSidebar(not collapsed) end)
		bindPress(closeButton, function() Main:Destroy() end)
		bindPress(minimizeButton, function() setWindowVisible(false) end)
		bindPress(maximizeButton, function()
			maximized = not maximized
			if maximized then
				tween(window, 0.22, {Size = UDim2.new(0.92, 0, 0.86, 0), Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quint)
			else
				tween(window, 0.22, {Size = UDim2.fromOffset(780, 470), Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quint)
			end
		end)
		bindPress(opener, function() setWindowVisible(true) end)

		track(UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not alive then return end
			if input.KeyCode == Enum.KeyCode.LeftControl then setWindowVisible(minimized) end
			if input.KeyCode == Enum.KeyCode.Escape then closeDropdown() end
		end))

		local dragging, dragStart, startPosition
		track(topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPosition = true, input.Position, window.Position
			end
		end))
		track(UserInputService.InputChanged:Connect(function(input)
			if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
			local delta = input.Position - dragStart
			window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
			shadow.Position = window.Position
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))

		if LocalPlayer then
			local displayName = LocalPlayer.DisplayName or LocalPlayer.Name or "Player"
			username.Text = shorten(displayName, 14)
			userSub.Text = "@" .. shorten(LocalPlayer.Name or "user", 16)
			task.spawn(function()
				local ok, image = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				if ok and type(image) == "string" and avatar.Parent then avatar.Image = image end
			end)
		end

		windowScale.Scale = responsiveScale * 0.92
		tween(windowScale, 0.28, {Scale = responsiveScale}, Enum.EasingStyle.Quint)
		return Main
	end

	return factory
end

-- // Init Library

local Main = library.create().Module()
library.notification({Title = "GAMZ Hub", Desc = "Thank you for using our scripts!", Type = 1})

-- // =====================================================
-- // Blox Fruits Module (dùng UI Luxury ở trên)
-- // =====================================================

local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local BLOX_PLACES = {[2753915549] = true, [4442272183] = true, [7449423635] = true}
if not BLOX_PLACES[game.PlaceId] then
	library.notification({Title = "Sai game", Desc = "Script này chỉ dành cho Blox Fruits.", Type = 2})
end

local running = true
local State = {
	AutoFarm = false, AutoClick = false, AutoHaki = false, AutoStats = false,
	AutoChest = false, FruitESP = false, PlayerESP = false, Noclip = false,
	Mob = nil, WeaponType = "Melee", Height = 16, TweenSpeed = 250,
	AutoLevel = false, FastAttack = false, LevelMob = nil,
	StatName = "Melee", WalkSpeed = 16, JumpPower = 50, WalkSpeedOn = false,
}

-- // Helpers
local function getChar() return LocalPlayer.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive() local h = getHum(); return h and h.Health > 0 end

local function remote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("CommF_")
end

local currentTween
local function tweenTo(cf, speed)
	local root = getRoot()
	if not root then return end
	if currentTween then pcall(function() currentTween:Cancel() end) end
	local distance = (root.Position - cf.Position).Magnitude
	currentTween = TweenService:Create(root, TweenInfo.new(math.max(distance / (speed or State.TweenSpeed), 0.05), Enum.EasingStyle.Linear), {CFrame = cf})
	currentTween:Play()
	return currentTween
end

local function getMobNames()
	local names, seen = {}, {}
	local folder = Workspace:FindFirstChild("Enemies")
	if folder then
		for _, mob in ipairs(folder:GetChildren()) do
			if not seen[mob.Name] then seen[mob.Name] = true; table.insert(names, mob.Name) end
		end
	end
	table.sort(names)
	return names
end

local function nearestMob()
	local root, folder = getRoot(), Workspace:FindFirstChild("Enemies")
	if not root or not folder then return nil end
	local best, bestDist
	local want = (State.AutoLevel and State.LevelMob) or State.Mob
	for _, mob in ipairs(folder:GetChildren()) do
		local hrp, hum = mob:FindFirstChild("HumanoidRootPart"), mob:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and (want == nil or mob.Name == want) then
			local d = (hrp.Position - root.Position).Magnitude
			if not bestDist or d < bestDist then best, bestDist = mob, d end
		end
	end
	return best
end

local function equipWeapon()
	local char, hum = getChar(), getHum()
	if not char or not hum then return end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == State.WeaponType then return end
	end
	for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == State.WeaponType then
			hum:EquipTool(tool)
			return
		end
	end
end

local function ensureHaki()
	local char, comm = getChar(), remote()
	if char and comm and not char:FindFirstChild("HasBuso") then
		pcall(function() comm:InvokeServer("Buso") end)
	end
end

-- // Quest data cho 3 Sea. Viết theo trí nhớ, CHƯA kiểm chứng trong game.
-- Mỗi dòng: {level tối thiểu, tên quest, số thứ tự quest, tên quái}
local QUESTS_SEA1 = {
	{1, "BanditQuest1", 1, "Bandit"},
	{10, "JungleQuest", 1, "Monkey"},
	{15, "JungleQuest", 2, "Gorilla"},
	{30, "BuggyQuest1", 1, "Pirate"},
	{40, "BuggyQuest1", 2, "Brute"},
	{60, "DesertQuest", 1, "Desert Bandit"},
	{75, "DesertQuest", 2, "Desert Officer"},
	{90, "SnowQuest", 1, "Snow Bandit"},
	{100, "SnowQuest", 2, "Snowman"},
	{120, "MarineQuest2", 1, "Chief Petty Officer"},
	{150, "SkyQuest", 1, "Sky Bandit"},
	{175, "SkyQuest", 2, "Dark Master"},
	{190, "PrisonerQuest", 1, "Prisoner"},
	{210, "PrisonerQuest", 2, "Dangerous Prisoner"},
	{250, "ColosseumQuest", 1, "Toga Warrior"},
	{275, "ColosseumQuest", 2, "Gladiator"},
	{300, "MagmaQuest", 1, "Military Soldier"},
	{325, "MagmaQuest", 2, "Military Spy"},
	{375, "FishmanQuest", 1, "Fishman Warrior"},
	{400, "FishmanQuest", 2, "Fishman Commando"},
	{450, "SkyExp1Quest", 1, "God's Guard"},
	{475, "SkyExp1Quest", 2, "Shanda"},
	{525, "SkyExp2Quest", 1, "Royal Squad"},
	{550, "SkyExp2Quest", 2, "Royal Soldier"},
	{625, "FountainQuest", 1, "Galley Pirate"},
	{650, "FountainQuest", 2, "Galley Captain"},
}

local QUESTS_SEA2 = {
	{700, "Area1Quest", 1, "Raider"},
	{725, "Area1Quest", 2, "Mercenary"},
	{775, "Area2Quest", 1, "Swan Pirate"},
	{800, "Area2Quest", 2, "Factory Staff"},
	{875, "MarineQuest3", 1, "Marine Lieutenant"},
	{900, "MarineQuest3", 2, "Marine Captain"},
	{950, "ZombieQuest", 1, "Zombie"},
	{975, "ZombieQuest", 2, "Vampire"},
	{1000, "SnowMountainQuest", 1, "Snow Trooper"},
	{1050, "SnowMountainQuest", 2, "Winter Warrior"},
	{1100, "IceSideQuest", 1, "Lab Subordinate"},
	{1125, "IceSideQuest", 2, "Horned Warrior"},
	{1175, "FireSideQuest", 1, "Magma Ninja"},
	{1200, "FireSideQuest", 2, "Lava Pirate"},
	{1250, "ShipQuest1", 1, "Ship Deckhand"},
	{1275, "ShipQuest1", 2, "Ship Engineer"},
	{1300, "ShipQuest2", 1, "Ship Steward"},
	{1325, "ShipQuest2", 2, "Ship Officer"},
	{1350, "FrostQuest", 1, "Arctic Warrior"},
	{1375, "FrostQuest", 2, "Snow Lurker"},
	{1425, "ForgottenQuest", 1, "Sea Soldier"},
	{1450, "ForgottenQuest", 2, "Water Fighter"},
}

local QUESTS_SEA3 = {
	{1500, "PiratePortQuest", 1, "Pirate Millionaire"},
	{1525, "PiratePortQuest", 2, "Pistol Billionaire"},
	{1575, "AmazonQuest", 1, "Dragon Crew Warrior"},
	{1600, "AmazonQuest", 2, "Dragon Crew Archer"},
	{1625, "AmazonQuest2", 1, "Female Islander"},
	{1650, "AmazonQuest2", 2, "Giant Islander"},
	{1700, "MarineTreeIsland", 1, "Marine Commodore"},
	{1725, "MarineTreeIsland", 2, "Marine Rear Admiral"},
	{1775, "DeepForestIsland2", 1, "Fishman Raider"},
	{1800, "DeepForestIsland2", 2, "Fishman Captain"},
	{1825, "DeepForestIsland", 1, "Forest Pirate"},
	{1850, "DeepForestIsland", 2, "Mythological Pirate"},
	{1900, "DeepForestIsland3", 1, "Jungle Pirate"},
	{1925, "DeepForestIsland3", 2, "Musketeer Pirate"},
	{1975, "HauntedQuest1", 1, "Reborn Skeleton"},
	{2000, "HauntedQuest1", 2, "Living Zombie"},
	{2025, "HauntedQuest2", 1, "Demonic Soul"},
	{2050, "HauntedQuest2", 2, "Posessed Mummy"},
	{2075, "NutsIslandQuest", 1, "Peanut Scout"},
	{2100, "NutsIslandQuest", 2, "Peanut President"},
	{2125, "IceCreamIslandQuest", 1, "Ice Cream Chef"},
	{2150, "IceCreamIslandQuest", 2, "Ice Cream Commander"},
	{2200, "CakeQuest1", 1, "Cookie Crafter"},
	{2225, "CakeQuest1", 2, "Cake Guard"},
	{2250, "CakeQuest2", 1, "Baking Staff"},
	{2275, "CakeQuest2", 2, "Head Baker"},
	{2300, "ChocQuest1", 1, "Cocoa Warrior"},
	{2325, "ChocQuest1", 2, "Chocolate Bar Battler"},
	{2350, "ChocQuest2", 1, "Sweet Thief"},
	{2375, "ChocQuest2", 2, "Candy Rebel"},
	{2400, "CandyQuest1", 1, "Candy Pirate"},
	{2425, "CandyQuest1", 2, "Snow Demon"},
	{2450, "TikiQuest1", 1, "Isle Outlaw"},
	{2475, "TikiQuest1", 2, "Island Boy"},
	{2500, "TikiQuest2", 1, "Sun-kissed Warrior"},
	{2525, "TikiQuest2", 2, "Isle Champion"},
}

local QUESTS_BY_PLACE = {
	[2753915549] = QUESTS_SEA1,
	[4442272183] = QUESTS_SEA2,
	[7449423635] = QUESTS_SEA3,
}
local QUESTS = QUESTS_BY_PLACE[game.PlaceId] or QUESTS_SEA1

local function getLevel()
	local data = LocalPlayer:FindFirstChild("Data")
	local lvl = data and data:FindFirstChild("Level")
	return lvl and lvl.Value or 1
end

local function currentQuest()
	local level, chosen = getLevel(), QUESTS[1]
	for _, q in ipairs(QUESTS) do
		if level >= q[1] then chosen = q end
	end
	return chosen
end

local function questActive()
	local ok, visible = pcall(function()
		return LocalPlayer.PlayerGui.Main.Quest.Visible
	end)
	return ok and visible
end

local lastQuestTry = 0
local function handleQuest()
	local q = currentQuest()
	State.LevelMob = q[4]
	if not questActive() and os.clock() - lastQuestTry > 3 then
		lastQuestTry = os.clock()
		local comm = remote()
		if comm then pcall(function() comm:InvokeServer("StartQuest", q[2], q[3]) end) end
	end
end

-- // Server Hop
local TeleportService = game:GetService("TeleportService")
local function serverHop()
	local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
	local ok, body = pcall(function()
		if type(request) == "function" then return request({Url = url, Method = "GET"}).Body end
		return game:HttpGet(url)
	end)
	if not ok or not body then return false, "Không gọi được API: " .. tostring(body) end
	local decoded, data = pcall(HttpService.JSONDecode, HttpService, body)
	if not decoded or type(data) ~= "table" or type(data.data) ~= "table" then return false, "Không đọc được danh sách server" end
	local candidates = {}
	for _, server in ipairs(data.data) do
		if server.id ~= game.JobId and server.playing and server.maxPlayers and server.playing < server.maxPlayers - 1 then
			table.insert(candidates, server.id)
		end
	end
	if #candidates == 0 then return false, "Không có server phù hợp" end
	local teleported, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, candidates[math.random(#candidates)], LocalPlayer)
	return teleported, err
end

-- // Loops
task.spawn(function() -- Auto Farm
	while running do
		if (State.AutoFarm or State.AutoLevel) and isAlive() then
			pcall(function()
				if State.AutoLevel then handleQuest() end
				equipWeapon()
				if State.AutoHaki then ensureHaki() end
				local mob = nearestMob()
				local root = getRoot()
				if mob and root then
					local target = mob.HumanoidRootPart.CFrame * CFrame.new(0, State.Height, 0) * CFrame.Angles(math.rad(-90), 0, 0)
					if (root.Position - target.Position).Magnitude > 100 then
						tweenTo(target)
					else
						if currentTween then currentTween:Cancel() end
						root.CFrame = target
						root.AssemblyLinearVelocity = Vector3.zero
					end
				end
			end)
		end
		task.wait(0.1)
	end
end)

task.spawn(function() -- Auto Click
	while running do
		if State.AutoClick and isAlive() then
			pcall(function()
				VirtualUser:CaptureController()
				for _ = 1, State.FastAttack and 3 or 1 do
					VirtualUser:Button1Down(Vector2.new(1280, 672))
					VirtualUser:Button1Up(Vector2.new(1280, 672))
				end
			end)
		end
		task.wait(State.FastAttack and 0.04 or 0.12)
	end
end)

task.spawn(function() -- Auto Stats
	while running do
		if State.AutoStats then
			local comm = remote()
			if comm then pcall(function() comm:InvokeServer("AddPoint", State.StatName, 1) end) end
		end
		task.wait(0.5)
	end
end)

task.spawn(function() -- Auto Chest
	while running do
		if State.AutoChest and isAlive() then
			pcall(function()
				local root, best, bestDist = getRoot(), nil, nil
				for _, chest in ipairs(CollectionService:GetTagged("_ChestTagged")) do
					if chest:IsA("BasePart") and chest.Parent then
						local d = (chest.Position - root.Position).Magnitude
						if not bestDist or d < bestDist then best, bestDist = chest, d end
					end
				end
				if best then
					local t = tweenTo(best.CFrame, State.TweenSpeed)
					if t then t.Completed:Wait() end
				end
			end)
		end
		task.wait(0.5)
	end
end)

local connections = {}
table.insert(connections, RunService.Stepped:Connect(function() -- Noclip
	if State.Noclip or State.AutoFarm or State.AutoLevel then
		local char = getChar()
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end
end))

table.insert(connections, RunService.Heartbeat:Connect(function() -- Speed / Jump
	if State.WalkSpeedOn then
		local hum = getHum()
		if hum then hum.WalkSpeed = State.WalkSpeed; hum.UseJumpPower = true; hum.JumpPower = State.JumpPower end
	end
end))

table.insert(connections, LocalPlayer.Idled:Connect(function() -- Anti AFK
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end))

-- // ESP
local espObjects = {}
local function clearESP(kind)
	for obj, info in pairs(espObjects) do
		if info.Kind == kind then pcall(function() info.Gui:Destroy() end); espObjects[obj] = nil end
	end
end

local function addESP(kind, adornee, text, color)
	if espObjects[adornee] then return end
	local gui = create("BillboardGui", {
		Adornee = adornee, AlwaysOnTop = true, Size = UDim2.fromOffset(140, 20), StudsOffset = Vector3.new(0, 3, 0),
	}, guiParent())
	create("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold,
		Text = text, TextColor3 = color, TextSize = 12, TextStrokeTransparency = 0.4,
	}, gui)
	espObjects[adornee] = {Gui = gui, Kind = kind}
end

task.spawn(function()
	while running do
		pcall(function()
			if State.FruitESP then
				for _, obj in ipairs(Workspace:GetChildren()) do
					if obj:IsA("Tool") and string.find(obj.Name, "Fruit") and obj:FindFirstChild("Handle") then
						addESP("Fruit", obj.Handle, obj.Name, Color3.fromRGB(255, 200, 60))
					end
				end
			end
			if State.PlayerESP then
				for _, plr in ipairs(Players:GetPlayers()) do
					local c = plr.Character
					if plr ~= LocalPlayer and c and c:FindFirstChild("Head") then
						addESP("Player", c.Head, plr.DisplayName, Color3.fromRGB(255, 95, 87))
					end
				end
			end
			for obj, info in pairs(espObjects) do
				if not obj.Parent then pcall(function() info.Gui:Destroy() end); espObjects[obj] = nil end
			end
		end)
		task.wait(1)
	end
end)

local function teleportToNearestFruit()
	local root, best, bestDist = getRoot(), nil, nil
	if not root then return false end
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Tool") and string.find(obj.Name, "Fruit") and obj:FindFirstChild("Handle") then
			local d = (obj.Handle.Position - root.Position).Magnitude
			if not bestDist or d < bestDist then best, bestDist = obj, d end
		end
	end
	if not best then return false end
	tweenTo(best.Handle.CFrame, State.TweenSpeed)
	return true, best.Name
end

-- // UI
-- // Logo GAMZ (ảnh nhúng sẵn, không cần upload lên Roblox)
local LOGO_B64 = table.concat({
	"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAQDAwMDAgQDAwMEBAQFBgoGBgUFBgwICQcKDgwPDg4MDQ0PERYTDxAVEQ0NExoTFRcY",
	"GRkZDxIbHRsYHRYYGRj/2wBDAQQEBAYFBgsGBgsYEA0QGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgY",
	"GBgYGBgYGBj/wAARCACgAKADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUF",
	"BAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW",
	"V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi",
	"4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC",
	"AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVm",
	"Z2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq",
	"8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8/wCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACi",
	"iigAooooAKKKKACux+FfgPWPiX8XdE8FaHZw3V1qE+wicssccYBaSRypB2qoZjg54wK46vpD9mWOT4daBr/7SUoW5t/CN1Bp405j",
	"t+1i7R4pMN2ZN8bAd8mgDyj4v6Z8P9F+L+r6N8M7vUb3w/ZSfZo7u+kV2uJF4kdMKMRls7c5OBnPNcNV3V5LefxBfTWbvJbvcSNE",
	"7jBZSxIJHY4xVPafSgBKKXa3oaTBFABRRRQAUUUUAFFFFABRRRQAUdTRU9vHvccUAJHbs/apxZN6Vs2VjuAwvWtqHQ5pVG2PP4UA",
	"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",
	"oAKKKKAP/9k=",
})

local function decodeBase64(data)
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local lookup = {}
	for i = 1, #alphabet do lookup[string.byte(alphabet, i)] = i - 1 end
	local out, bits, count = {}, 0, 0
	for i = 1, #data do
		local value = lookup[string.byte(data, i)]
		if value then
			bits = bits * 64 + value
			count = count + 1
			if count == 4 then
				table.insert(out, string.char(math.floor(bits / 65536) % 256, math.floor(bits / 256) % 256, bits % 256))
				bits, count = 0, 0
			end
		end
	end
	if count == 2 then
		table.insert(out, string.char(math.floor(bits / 16) % 256))
	elseif count == 3 then
		table.insert(out, string.char(math.floor(bits / 1024) % 256, math.floor(bits / 4) % 256))
	end
	return table.concat(out)
end

local function loadGamzLogo()
	local assetFn = (type(getcustomasset) == "function" and getcustomasset) or (type(getsynasset) == "function" and getsynasset)
	if type(writefile) ~= "function" or not assetFn then return nil end
	local ok, asset = pcall(function()
		writefile("gamz_logo.jpg", decodeBase64(LOGO_B64))
		return assetFn("gamz_logo.jpg")
	end)
	return ok and asset or nil
end

local gamzLogo = loadGamzLogo()
if gamzLogo then Main:SetLogo(gamzLogo) end


local FarmSection = Main.section({Title = "Farm", Category = "Blox Fruits"})
local FarmPage = FarmSection.page({Title = "Auto Farm", Description = "Farm quái theo tên"})

local mobDrop = FarmPage.Dropdown({Title = "Chọn quái", item = getMobNames(), multi = false, callback = function(v)
	State.Mob = (type(v) == "table" and v[1]) or v
end})

FarmPage.Button({Title = "Làm mới danh sách quái", Description = "Quét quái đang có quanh bạn", callback = function()
	mobDrop.Clear()
	mobDrop.Add(getMobNames())
end})

FarmPage.Dropdown({Title = "Loại vũ khí", item = {"Melee", "Sword", "Blox Fruit", "Gun"}, multi = false, callback = function(v)
	State.WeaponType = (type(v) == "table" and v[1]) or v
end})

FarmPage.Slider({Title = "Độ cao trên quái", Min = 5, Max = 30, Default = 16, Type = "studs", Flag = "Height", callback = function(v) State.Height = v end})
FarmPage.Slider({Title = "Tốc độ bay", Min = 100, Max = 350, Default = 250, Flag = "TweenSpeed", callback = function(v) State.TweenSpeed = v end})

FarmPage.Toggle({Title = "Auto Farm Level (Sea 1/2/3)", Description = "Tự nhận quest và farm theo level", Flag = "AutoLevel", callback = function(v)
	State.AutoLevel = v
	if v then
		local level = getLevel()
		if level < QUESTS[1][1] then
			library.notification({Title = "Sai Sea?", Desc = "Level " .. level .. " thấp hơn mức bắt đầu của Sea này (" .. QUESTS[1][1] .. "). Hãy đổi Sea phù hợp.", Type = 2})
		else
			library.notification({Title = "Auto Farm Level", Desc = "Tự nhận Sea theo game hiện tại. Dữ liệu quest chưa kiểm chứng.", Type = 3})
		end
	end
end})
FarmPage.Toggle({Title = "Fast Attack", Description = "Đánh nhanh hơn (tăng số lần click)", Flag = "FastAttack", callback = function(v) State.FastAttack = v end})
FarmPage.Toggle({Title = "Auto Farm", Description = "Bay tới quái gần nhất và đứng trên đầu", Flag = "AutoFarm", callback = function(v) State.AutoFarm = v end})
FarmPage.Toggle({Title = "Auto Click", Description = "Tự đánh liên tục", Flag = "AutoClick", callback = function(v) State.AutoClick = v end})
FarmPage.Toggle({Title = "Auto Haki", Description = "Tự bật Buso Haki", Flag = "AutoHaki", callback = function(v) State.AutoHaki = v end})

local StatsPage = FarmSection.page({Title = "Chỉ số", Description = "Tự cộng điểm"})
StatsPage.Dropdown({Title = "Chỉ số", item = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}, multi = false, callback = function(v)
	State.StatName = (type(v) == "table" and v[1]) or v
end})
StatsPage.Toggle({Title = "Auto cộng điểm", Flag = "AutoStats", callback = function(v) State.AutoStats = v end})

local MiscSection = Main.section({Title = "Khám phá", Category = "Blox Fruits"})
local ItemPage = MiscSection.page({Title = "Rương & Trái ác quỷ"})
ItemPage.Toggle({Title = "Auto nhặt rương", Description = "Bay tới rương gần nhất", Flag = "AutoChest", callback = function(v) State.AutoChest = v end})
ItemPage.Toggle({Title = "ESP Trái ác quỷ", Flag = "FruitESP", callback = function(v)
	State.FruitESP = v
	if not v then clearESP("Fruit") end
end})
ItemPage.Button({Title = "Bay tới trái gần nhất", callback = function()
	local ok, name = teleportToNearestFruit()
	library.notification({Title = ok and "Đang bay tới trái" or "Không có trái", Desc = ok and tostring(name) or "Chưa có trái nào xuất hiện trong server.", Type = ok and 1 or 3})
end})

local PlayerPage = MiscSection.page({Title = "Nhân vật"})
PlayerPage.Toggle({Title = "Chỉnh tốc độ / nhảy", Flag = "WalkSpeedOn", callback = function(v)
	State.WalkSpeedOn = v
	if not v then local h = getHum(); if h then h.WalkSpeed = 16; h.JumpPower = 50 end end
end})
PlayerPage.Slider({Title = "Tốc độ chạy", Min = 16, Max = 120, Default = 16, Flag = "WalkSpeed", callback = function(v) State.WalkSpeed = v end})
PlayerPage.Slider({Title = "Sức nhảy", Min = 50, Max = 200, Default = 50, Flag = "JumpPower", callback = function(v) State.JumpPower = v end})
PlayerPage.Toggle({Title = "Noclip", Description = "Đi xuyên vật cản", Flag = "Noclip", callback = function(v) State.Noclip = v end})
PlayerPage.Toggle({Title = "ESP người chơi", Flag = "PlayerESP", callback = function(v)
	State.PlayerESP = v
	if not v then clearESP("Player") end
end})

local HopPage = MiscSection.page({Title = "Server"})
HopPage.Button({Title = "Server Hop", Description = "Chuyển sang server công khai khác", ButtonText = "Hop", callback = function()
	library.notification({Title = "Server Hop", Desc = "Đang tìm server...", Type = 3})
	local ok, err = serverHop()
	if not ok then library.notification({Title = "Server Hop lỗi", Desc = tostring(err), Type = 2}) end
end})

local SettingsSection = Main.section({Title = "Cài đặt", Category = "Hệ thống"})
local ConfigPage = SettingsSection.page({Title = "Cấu hình"})
ConfigPage.Button({Title = "Lưu cấu hình", ButtonText = "Lưu", callback = function()
	local ok, err = Main.SaveConfig(Main, "gamz_bloxfruits.json")
	library.notification({Title = ok and "Đã lưu" or "Lỗi", Desc = ok and "gamz_bloxfruits.json" or tostring(err), Type = ok and 1 or 2})
end})
ConfigPage.Button({Title = "Tải cấu hình", ButtonText = "Tải", callback = function()
	local ok, err = Main.LoadConfig(Main, "gamz_bloxfruits.json")
	library.notification({Title = ok and "Đã tải" or "Lỗi", Desc = ok and "Đã áp dụng cấu hình" or tostring(err), Type = ok and 1 or 2})
end})
ConfigPage.Button({Title = "Tắt hết & đóng script", ButtonText = "Gỡ", callback = function()
	running = false
	for key, value in pairs(State) do if value == true then State[key] = false end end
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	clearESP("Fruit"); clearESP("Player")
	if currentTween then pcall(function() currentTween:Cancel() end) end
	local h = getHum(); if h then h.WalkSpeed = 16; h.JumpPower = 50 end
	Main:Destroy()
end})

return library
