-- 5q4i Key System GUI
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local KEY = "1" -- change this to your key
local FONT = Enum.Font.Gotham -- thin font for all body text
local TITLE_FONT = Enum.Font.GothamMedium -- title only
local SLIDER_MIN, SLIDER_MAX, SLIDER_DEFAULT = 0, 20, 5 -- slider caps at SLIDER_MAX; the textbox has no upper limit
local MAX_VISIBLE_OPTIONS = 4 -- dropdown scrolls if there are more
local HOME_WIDTH, HOME_HEIGHT = 260, 320 -- second page size (taller than wide)

-- Dropdown options: add / remove / rename strings here
local DROPDOWN_OPTIONS = {
	"Speed",
	"Jump Power",
	"Gravity",
}

local THEME = {
	Bg        = Color3.fromRGB(13, 13, 15),
	Panel     = Color3.fromRGB(22, 22, 26),
	PanelAlt  = Color3.fromRGB(28, 28, 33),
	Stroke    = Color3.fromRGB(45, 45, 52),
	Red       = Color3.fromRGB(200, 16, 32),
	RedHover  = Color3.fromRGB(235, 40, 55),
	BloodDark = Color3.fromRGB(100, 0, 8),
	Text      = Color3.fromRGB(235, 235, 240),
	SubText   = Color3.fromRGB(115, 115, 125),
	Success   = Color3.fromRGB(255, 255, 255),
}

-- ===== HELPERS =====
local function new(class, props)
	local inst = Instance.new(class)
	if class == "UIStroke" then
		inst.LineJoinMode = Enum.LineJoinMode.Miter -- sharp, tight corners
	end
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	inst.Parent = props.Parent
	return inst
end

local function tween(obj, time, goal, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local function makeRedButton(text, y, parent)
	local b = new("TextButton", {
		Position = UDim2.fromOffset(14, y),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundColor3 = THEME.Red,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT,
		Text = text,
		TextSize = 12,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = parent,
	})
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundColor3 = THEME.RedHover }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundColor3 = THEME.Red }) end)
	return b
end

--[[
	LaunchKeySystem(options)
	options = { "Name 1", "Name 2", ... }  -> shown in the dropdown
	ACTIVATE prints the selected option's name.
	Returns the ScreenGui.
]]
local function LaunchKeySystem(options)
	options = options or {}
	if #options == 0 then options = { "NONE" } end

	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("KeySystem")
	if old then old:Destroy() end -- prevents duplicates if launched twice

	local connections = {} -- global connections, cleaned up when GUI is destroyed

	-- ===== SCREEN GUI =====
	local gui = new("ScreenGui", {
		Name = "KeySystem",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	-- ===== MAIN FRAME =====
	local CENTER = UDim2.fromScale(0.5, 0.5)
	local main = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTER + UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(340, 140),
		BackgroundColor3 = THEME.Bg,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = gui,
	})
	new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = main })

	local UI_SCALE = 1.15 -- whole UI 15% bigger
	local uiScale = new("UIScale", { Parent = main })
	local function updateScale()
		local vp = workspace.CurrentCamera.ViewportSize
		uiScale.Scale = UI_SCALE * math.clamp(math.min(vp.X / 900, vp.Y / 500), 0.6, 1)
	end
	updateScale()
	table.insert(connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))

	-- ===== HEADER =====
	local title = new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 7),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = TITLE_FONT,
		Text = "5q4i",
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main,
	})
	local titleGrad = new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(220, 10, 25)),
			ColorSequenceKeypoint.new(1, THEME.BloodDark),
		}),
		Offset = Vector2.new(0, -0.15),
		Parent = title,
	})
	TweenService:Create(titleGrad,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Offset = Vector2.new(0, 0.15) }
	):Play()

	local subtitle = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 7),
		Size = UDim2.new(1, -80, 0, 24),
		Font = FONT,
		Text = "ENTER KEY TO CONTINUE",
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = main,
	})

	-- ===== PAGES =====
	local PAGE_POS = UDim2.fromOffset(0, 42)
	local function makePage(name, visible)
		return new("CanvasGroup", {
			Name = name,
			BackgroundTransparency = 1,
			Position = PAGE_POS,
			Size = UDim2.new(1, 0, 1, -42),
			GroupTransparency = visible and 0 or 1,
			Visible = visible,
			Parent = main,
		})
	end

	local keyPage = makePage("KeyPage", true)
	local homePage = makePage("HomePage", false)

	local function switchPage(from, to)
		to.Position = PAGE_POS + UDim2.fromOffset(8, 0)
		to.GroupTransparency = 1
		to.Visible = true
		tween(from, 0.15, { GroupTransparency = 1, Position = PAGE_POS + UDim2.fromOffset(-8, 0) })
		tween(to, 0.18, { GroupTransparency = 0, Position = PAGE_POS }).Completed:Wait()
		from.Visible = false
	end

	-- ===== PAGE 1: KEY =====
	local boxHolder = new("Frame", {
		Position = UDim2.fromOffset(14, 4),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		Parent = keyPage,
	})
	local boxStroke = new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = boxHolder })
	new("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = THEME.Red,
		BorderSizePixel = 0,
		Parent = boxHolder,
	})
	local keyBox = new("TextBox", {
		Name = "KeyBox",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Font = FONT,
		Text = "",
		PlaceholderText = "sd-xxxx-xxxxx",
		PlaceholderColor3 = THEME.SubText,
		TextColor3 = THEME.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = boxHolder,
	})

	local submitButton = makeRedButton("Redeem key", 42, keyPage)

	local status = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 80),
		Size = UDim2.new(1, -28, 0, 12),
		Font = FONT,
		Text = "",
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = keyPage,
	})

	-- ===== PAGE 2: CONTROLS =====
	local selectedOption = tostring(options[1])
	local value = SLIDER_DEFAULT

	-- --- Dropdown ---
	local dropHolder = new("Frame", {
		Position = UDim2.fromOffset(14, 4),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		Parent = homePage,
	})
	local dropStroke = new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = dropHolder })
	new("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = THEME.Red,
		BorderSizePixel = 0,
		Parent = dropHolder,
	})
	local dropButton = new("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		Font = FONT,
		Text = selectedOption,
		TextSize = 12,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = dropHolder,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 24), Parent = dropButton })

	local arrow = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(10, 6),
		BackgroundTransparency = 1,
		Parent = dropHolder,
	})
	local barL = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(7, 2),
		Rotation = 45,
		BackgroundColor3 = THEME.SubText,
		BorderSizePixel = 0,
		Parent = arrow,
	})
	local barR = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(7, 3),
		Size = UDim2.fromOffset(7, 2),
		Rotation = -45,
		BackgroundColor3 = THEME.SubText,
		BorderSizePixel = 0,
		Parent = arrow,
	})

	local OPTION_H = 24
	local listHeight = math.min(#options, MAX_VISIBLE_OPTIONS) * OPTION_H
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 0, 0),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = THEME.Red,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = homePage,
	})
	new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = list })
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local isOpen = false
	local function setDropdown(state)
		isOpen = state
		tween(barL, 0.15, { Rotation = state and -45 or 45 })
		tween(barR, 0.15, { Rotation = state and 45 or -45 })
		tween(dropStroke, 0.15, { Color = state and THEME.Red or THEME.Stroke })
		if state then
			list.Visible = true
			tween(list, 0.15, { Size = UDim2.new(1, -28, 0, listHeight) })
		else
			tween(list, 0.12, { Size = UDim2.new(1, -28, 0, 0) }).Completed:Connect(function()
				if not isOpen then list.Visible = false end
			end)
		end
	end

	local optionButtons = {}
	local function refreshOptions()
		for _, entry in ipairs(optionButtons) do
			entry.Button.TextColor3 = (entry.Name == selectedOption) and THEME.Red or THEME.SubText
		end
	end

	for i, raw in ipairs(options) do
		local name = tostring(raw)
		local o = new("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, OPTION_H),
			BackgroundColor3 = THEME.PanelAlt,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = FONT,
			Text = name,
			TextSize = 11,
			TextColor3 = THEME.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 6,
			Parent = list,
		})
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = o })
		table.insert(optionButtons, { Name = name, Button = o })
		o.MouseEnter:Connect(function() tween(o, 0.1, { BackgroundColor3 = THEME.Stroke }) end)
		o.MouseLeave:Connect(function() tween(o, 0.1, { BackgroundColor3 = THEME.PanelAlt }) end)
		o.Activated:Connect(function()
			selectedOption = name
			dropButton.Text = name
			refreshOptions()
			setDropdown(false)
		end)
	end
	refreshOptions()
	dropButton.Activated:Connect(function() setDropdown(not isOpen) end)

	-- --- Slider + number box ---
	local SLIDER_Y = 40
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(14, SLIDER_Y + 14),
		Size = UDim2.new(1, -92, 0, 4),
		BackgroundColor3 = THEME.Stroke,
		BorderSizePixel = 0,
		Parent = homePage,
	})
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = THEME.Red,
		BorderSizePixel = 0,
		Parent = track,
	})
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(6, 16),
		BackgroundColor3 = THEME.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	local sliderHit = new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Position = UDim2.fromOffset(8, SLIDER_Y),
		Size = UDim2.new(1, -80, 0, 28),
		Parent = homePage,
	})

	local valueBox = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, SLIDER_Y),
		Size = UDim2.fromOffset(56, 28),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		Font = FONT,
		Text = "",
		PlaceholderText = SLIDER_MIN .. "+",
		PlaceholderColor3 = THEME.SubText,
		TextColor3 = THEME.Text,
		TextSize = 12,
		ClearTextOnFocus = true,
		Parent = homePage,
	})
	local valueStroke = new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = valueBox })

	local function formatValue(v)
		if v == math.floor(v) then return tostring(math.floor(v)) end
		return string.format("%.1f", v)
	end

	local function setValue(v, snap, uncapped)
		if snap then
			v = math.floor(v + 0.5)
		else
			v = math.floor(v * 10 + 0.5) / 10
		end
		if uncapped then
			v = math.max(v, SLIDER_MIN) -- textbox: no upper limit
		else
			v = math.clamp(v, SLIDER_MIN, SLIDER_MAX)
		end
		value = v
		-- slider visual stays full when the typed value is above SLIDER_MAX
		local pct = math.clamp((v - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN), 0, 1)
		tween(fill, 0.08, { Size = UDim2.fromScale(pct, 1) })
		tween(knob, 0.08, { Position = UDim2.fromScale(pct, 0.5) })
		valueBox.Text = formatValue(v)
	end
	setValue(SLIDER_DEFAULT, true)

	local sliding = false
	local function slideTo(x)
		local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(SLIDER_MIN + pct * (SLIDER_MAX - SLIDER_MIN), true)
	end

	sliderHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			tween(knob, 0.1, { BackgroundColor3 = THEME.Red })
			slideTo(input.Position.X)
		end
	end)
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			sliding = false
			tween(knob, 0.1, { BackgroundColor3 = THEME.Text })
		end
	end))

	valueBox.Focused:Connect(function() tween(valueStroke, 0.15, { Color = THEME.Red }) end)
	valueBox.FocusLost:Connect(function()
		tween(valueStroke, 0.15, { Color = THEME.Stroke })
		local n = tonumber(valueBox.Text)
		if n and n == n and n ~= math.huge and n ~= -math.huge then
			setValue(n, false, true)
		else
			valueBox.Text = formatValue(value)
		end
	end)

	-- --- Switch: Old ---
	local oldEnabled = false
	local SWITCH_Y = 100 -- extra gap so the switch sits apart from the controls above

	new("TextLabel", {
		Name = "OldWarning",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, SWITCH_Y - 16),
		Size = UDim2.new(1, -28, 0, 12),
		Font = FONT,
		Text = "needs ping under 100",
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = homePage,
	})
	local switchHolder = new("TextButton", {
		Name = "OldSwitch",
		Position = UDim2.fromOffset(14, SWITCH_Y),
		Size = UDim2.new(1, -28, 0, 28),
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = homePage,
	})
	new("UIStroke", { Color = THEME.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = switchHolder })
	new("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = THEME.Red,
		BorderSizePixel = 0,
		Parent = switchHolder,
	})
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Font = FONT,
		Text = "OLD",
		TextSize = 12,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = switchHolder,
	})
	local switchTrack = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(28, 14),
		BackgroundColor3 = THEME.PanelAlt,
		BorderSizePixel = 0,
		Parent = switchHolder,
	})
	new("UIStroke", { Color = THEME.Stroke, Thickness = 1, Parent = switchTrack })
	local switchKnob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = THEME.SubText,
		BorderSizePixel = 0,
		Parent = switchTrack,
	})

	local function setOld(state)
		oldEnabled = state
		tween(switchKnob, 0.12, {
			Position = state and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = state and THEME.Text or THEME.SubText,
		})
		tween(switchTrack, 0.12, { BackgroundColor3 = state and THEME.Red or THEME.PanelAlt })
	end
	switchHolder.Activated:Connect(function() setOld(not oldEnabled) end)

	-- --- Activate button + footer (pinned to the bottom) ---
	local activateButton = makeRedButton("ACTIVATE", 0, homePage)
	activateButton.AnchorPoint = Vector2.new(0, 1)
	activateButton.Position = UDim2.new(0, 14, 1, -26)

	local footer = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 1, -20),
		Size = UDim2.new(1, -28, 0, 12),
		Font = FONT,
		Text = "READY",
		TextSize = 10,
		TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = homePage,
	})

	activateButton.Activated:Connect(function()
		if isOpen then setDropdown(false) end
		print(selectedOption)
	end)

	-- ===== WINDOW DRAGGING =====
	local dragging, dragStart, startPos = false, nil, nil

	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end
	for _, handle in ipairs({ main, keyPage, homePage }) do
		handle.InputBegan:Connect(beginDrag)
	end

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if sliding then
			slideTo(input.Position.X)
		elseif dragging then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))

	-- ===== KEY LOGIC =====
	local busy = false

	-- Glowing "Get key in discord" hint shown in the key box after a wrong key
	local DEFAULT_PLACEHOLDER = keyBox.PlaceholderText
	local glowTweens = {}
	local function setKeyHint(on)
		for _, t in ipairs(glowTweens) do t:Cancel() end
		table.clear(glowTweens)
		if on then
			keyBox.Text = ""
			keyBox.PlaceholderText = "Get key in discord"
			keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
			local info = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			table.insert(glowTweens, TweenService:Create(keyBox, info, { PlaceholderColor3 = Color3.fromRGB(255, 255, 255) }))
			for _, t in ipairs(glowTweens) do t:Play() end
		else
			keyBox.PlaceholderText = DEFAULT_PLACEHOLDER
			keyBox.PlaceholderColor3 = THEME.SubText
		end
	end

	local function setStatus(text, color)
		status.Text = text
		status.TextColor3 = color or THEME.SubText
	end

	local function shake()
		local base = main.Position
		for _, dx in ipairs({ -3, 3, -2, 0 }) do
			tween(main, 0.04, { Position = base + UDim2.fromOffset(dx, 0) }).Completed:Wait()
		end
	end

	local function submit()
		if busy then return end
		local input = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if input == "" then
			setStatus("PLEASE ENTER A KEY", THEME.Red)
			shake()
			return
		end

		busy = true
		submitButton.Text = "CHECKING..."
		setStatus("VERIFYING KEY...", THEME.SubText)
		task.wait(0.4)

		if input == KEY then
			setStatus("KEY ACCEPTED", THEME.Success)
			submitButton.Text = "ACCESS GRANTED"
			task.wait(0.5)
			subtitle.Text = "WELCOME, " .. player.DisplayName:upper()
			tween(main, 0.3, { Size = UDim2.fromOffset(HOME_WIDTH, HOME_HEIGHT) })
			switchPage(keyPage, homePage)
		else
			setStatus("INVALID KEY", THEME.Red)
			setKeyHint(true)
			submitButton.Text = "Redeem key"
			shake()
			busy = false
		end
	end

	submitButton.Activated:Connect(submit)

	keyBox.Focused:Connect(function()
		setKeyHint(false) -- back to the normal hint once the player clicks in to type
		tween(boxStroke, 0.15, { Color = THEME.Red })
	end)
	keyBox.FocusLost:Connect(function(enter)
		tween(boxStroke, 0.15, { Color = THEME.Stroke })
		if enter then submit() end
	end)

	-- cleanup global connections when the GUI is removed
	gui.Destroying:Connect(function()
		for _, c in ipairs(connections) do c:Disconnect() end
	end)

	-- intro animation
	tween(main, 0.2, { Position = CENTER })

	return gui
end

-- =====================================================
-- ===== LAUNCH IT (edit this part) =====
-- =====================================================
LaunchKeySystem(DROPDOWN_OPTIONS)