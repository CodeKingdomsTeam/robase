stds.roblox = {
	read_globals = {
		-- global functions
		"script",
		"warn",
		"wait",
		"spawn",
		"delay",
		"tick",
		"UserSettings",
		"settings",
		"time",
		"typeof",
		"game",
		"unpack",
		"getfenv",
		"setfenv",
		"shared",
		"workspace",
		"plugin",
		-- types
		"Axes",
		"BrickColor",
		"CFrame",
		"Color3",
		"ColorSequence",
		"ColorSequenceKeypoint",
		"Enum",
		"Faces",
		"Instance",
		"NumberRange",
		"NumberSequence",
		"NumberSequenceKeypoint",
		"PhysicalProperties",
		"Ray",
		"Random",
		"Rect",
		"Region3",
		"Region3int16",
		"TweenInfo",
		"UDim",
		"UDim2",
		"Vector2",
		"Vector3",
		"Vector3int16",
		"DockWidgetPluginGuiInfo",
		-- libraries
		"utf8",
		math = {
			fields = {
				"clamp",
				"sign",
				"noise"
			}
		},
		debug = {
			fields = {
				"profilebegin",
				"profileend",
				"traceback"
			}
		}
	}
}

std = "lua51+roblox"

files["spec/*.lua"] = {
	std = "+busted"
}

-- prevent max line lengths
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false
