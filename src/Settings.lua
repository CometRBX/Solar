--[[

	-------------------------------

	Solar Admin System - Version 0.3.3 Beta
	
	-------------------------------
	
	Developed by Starnamics - Exp_Bread - S1mp1eDude
	License: MIT License
	
	-------------------------------
	
	For detailed instructions on setting up Solar, please read our documentation (located on our DevForum post)
	https://devforum.roblox.com/t/solar-admin-system-lightweight-command-bar/1624370
	
	NOTICE:
	SOLAR ADMIN IS CURRENTLY IN BETA, MEANING:
	- SOME FEATURES MAY NOT WORK CORRECTLY
	- THERE MAY BE BUGS
	
	IT IS NOT RECOMMENDED YOU USE SOLAR ADMIN BETA IN PRODUCTION
	
	PLEASE REPORT ANY BUGS OR ISSUES ON THE DEVFORUM POST
	
--]]

local ConfigurationFolder = script.Parent:WaitForChild("Configuration")
local Events = script.Parent:WaitForChild("Events")
local SolarUI = script.Parent:WaitForChild("Assets"):WaitForChild("SolarUI")

local Settings = {

	--// Command Bar
	CommandBarHotkeys = { Enum.KeyCode.Quote }, --// Keys used to open the command bar
	IsCommandBarRestricted = false, --// Is the command bar accessible to non-moderators

	--// User Interface
	Theme = ConfigurationFolder:WaitForChild("Themes")["default.theme"], --// Theme of the UI
	
	--// Locations
	CommandsFolder = ConfigurationFolder:WaitForChild("Commands"), --// The location of your commands
	PluginsFolder = ConfigurationFolder:WaitForChild("Plugins"), --// The location of your plugins [EXPERIMENTAL]
	ThemesFolder = ConfigurationFolder:WaitForChild("Themes"), --// The location of your themes
	
	RegisterCommandDescendants = true, --// Should the module register the descendants of the commands folder or just the children?
	
	--// Debugging
	LogAPIErrors = true, --// Should API Errors be logged to console/output
	LogAPIInfo = true, --// Should API Info be logged to console/output
	
	--// Data Saving
	DataStoreKey = "DefaultDataStoreKey", --// You should replace this to something random!
	SavedData = { --// Data which is saved when player leaves game
		PermissionLevel = true, --// Should a players permission level be saved?
		GameHistory = true, --// Should a players history be saved? (recommended)
		ExecutionLog = false, --// Should a players command execution history be saved?
	},
	
	--// Permissions	
	--[[
		
		Permissions are used to manage who can do what using Solar
		
		Level 1 = No permissions (player)
		Level 2 = Some permissions (moderator)
		Level 3 = Most permissions (administrator)
		Level 4 = All permissions (head administrator)
	--]]
	
	Permissions = {
		Players = { --// Player permissions
			--// Below is an example, you should replace this with your own values!
			
			[00000000] = { --// The UserId or Username of the player (UserId is recommended)
				Level = 4, --// The permission level of the player
			},
			
		},
			
		Groups = { --// Group permissions
			--// Below is an example, you should replace this with your own values!
			
			[00000000] = { --// The Group Id
				Level = 1, --// The permission level for the entire group
				Ranks = { --// The levels for each group rank
					
					[255] = { --// The ID of the group rank
						Level = 3, --// The permission level for the role
						Operator = "==", --// The relational operator for this role (read the docs for more information)
					},
					
				},
			},
			
		},
		
		Assets = { --// Asset permissions
			--// Below is an example, you should replace this with your own values!
			
			[00000000] = { --// The asset's ID
				Level = 3, --// The permission level for the players who own the asset
				Type = "gamepass", --// The value type (if you entered a gamepass's ID, type 'gamepass', otherwise type 'asset')
			},
			
		},
	},

}
Settings.ThemeSelectorKey = Enum.KeyCode.LeftControl

return Settings
