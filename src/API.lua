--// Module

local API = {}
API._version = "0.3.3"

--// Services & Modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SolarFolder = ReplicatedStorage:WaitForChild("Solar")
local Configuration = SolarFolder:WaitForChild("Configuration")
local Settings = require(SolarFolder:WaitForChild("Settings"))
local CommandsFolder = Settings.CommandsFolder
local PluginsFolder = Settings.PluginsFolder
local ThemesFolder = Settings.ThemesFolder

local Events = SolarFolder:WaitForChild("Events")
local ActionEvents = Events:WaitForChild("Actions")
local CommandEvents = Events:WaitForChild("Commands")
local UIEvents = Events:WaitForChild("UI")
local RunService = game:GetService("RunService")
local PlayersService = game:GetService("Players")
local PolicyService 
local MarketplaceService 
local LocalizationService 
local DataStoreService
local SolarUI = SolarFolder:WaitForChild("Assets"):WaitForChild("SolarUI")
local MiscEvents = Events:WaitForChild("Misc")

--// Server Only Services & Modules
if RunService:IsServer() then
	PolicyService = game:GetService("PolicyService")
	MarketplaceService = game:GetService("MarketplaceService")
	LocalizationService = game:GetService("LocalizationService")
	DataStoreService = game:GetService("DataStoreService")
end

--// DataStore

local SolarStore
if RunService:IsServer() then
	SolarStore = DataStoreService:GetDataStore(Settings.DataStoreKey)
end

--// Global Variables

local Players = {}
local Commands = {}
local RegisteredPlugins = {}
local RegisteredThemes = {}

--// Internal Variables

local ValidTypes = {
	"player",
	"string",
	"multistring",
	"boolean",
	"number",
}

--// Types

export type RegisteredPlayer = {
	AccountAge: number,
	DisplayName: string,
	Username: string,
	ExecutionLog: {any},
	GameHistory: {any},
	JoinTime: number,
	LogExecution: (command: string,arguments: {}?,response: any) -> ({{	
		command: string,
		arguments: string,
		response: string,
		time: number,
	}}),
	LogHistory: () -> (
	{any}
	),
	PermissionLevel: number,
	PolicyInfo: {any},
	Region: string,
	SetPermission: (permissionLevel: number?),
	UserId: number,
	Player: Player,
}

--// Internal Functions

function LogError(...)
	local t = table.pack(...)
	if Settings.LogAPIErrors == true then
		warn(table.unpack(t))
	end
end

function LogInfo(...)
	local t = table.pack(...)
	if Settings.LogAPIInfo == true then
		print(table.unpack(t))
	end
end

function GetDefaultPermissionForPlayer(player: Player)
	if not player then return nil end
	local Permissions = Settings.Permissions

	local PlayerPermissionLevel = 1

	if Permissions.Players[player.Name] then
		PlayerPermissionLevel = Permissions.Players[player.Name].Level
	elseif Permissions.Players[player.UserId] then
		PlayerPermissionLevel = Permissions.Players[player.UserId].Level		
	end	

	for GroupId, Data in pairs(Permissions.Groups) do
		local PlayerRank = player:GetRankInGroup(GroupId)
		if PlayerRank > 0 then
			if PlayerPermissionLevel < Data.Level then
				PlayerPermissionLevel = Data.Level
			end
		end
		for RankId, RankData in pairs(Data.Ranks) do
			if RankData.Operator == "==" then
				if PlayerRank == RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			elseif RankData.Operator == ">=" then
				if PlayerRank >= RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			elseif RankData.Operator == "<=" then
				if PlayerRank <= RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			elseif RankData.Operator == ">" then
				if PlayerRank > RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			elseif RankData.Operator == "<" then	
				if PlayerRank < RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			elseif RankData.Operator == "~=" then
				if PlayerRank ~= RankId and PlayerPermissionLevel < RankData.Level then
					PlayerPermissionLevel = RankData.Level
				end
			end
		end
	end

	for AssetId, AssetData in pairs(Permissions.Assets) do
		if AssetData.Type == "asset" then
			pcall(function()
				if MarketplaceService:PlayerOwnsAsset(player,AssetId) then
					PlayerPermissionLevel = AssetData.Level
				end
			end)
		elseif AssetData.Type == "gamepass" then
			pcall(function()
				if MarketplaceService:UserOwnsGamePassAsync(player.UserId,AssetId) then
					PlayerPermissionLevel = AssetData.Level
				end
			end)
		end
	end

	if PlayerPermissionLevel == nil then return 1 end
	if type(PlayerPermissionLevel) ~= "number" then return 1 end
	if PlayerPermissionLevel > 4 then return 4 end
	if PlayerPermissionLevel < 1 then return 1 end
	return PlayerPermissionLevel
end

--// Shared APIs can be accessed by both client & server
local SharedAPIs = { 

}

--// Client APIs can be accessed only by client
local ClientAPIs = {

}






--// Player Functions





local PlayerDataTable = {}
PlayerDataTable.__index = PlayerDataTable

function PlayerDataTable:SetPermission(permissionLevel: number | nil)
	if permissionLevel and type(permissionLevel) == "number" then
		self["PermissionLevel"] = permissionLevel
		UIEvents:WaitForChild("PlayerChanged"):FireClient(self.Player,"PermissionLevel")
		return self
	end
	self["PermissionLevel"] = GetDefaultPermissionForPlayer(self.Player)
	UIEvents:WaitForChild("PlayerChanged"):FireClient(self.Player,"PermissionLevel")
	return self["PermissionLevel"]
end

function PlayerDataTable:LogExecution(command: string,arguments: {}?,response: any)
	if command and arguments and response then
		local executionDataTable = {
			command = command,
			arguments = arguments,
			response = response,
			time = os.time(),
		}
		table.insert(self["ExecutionLog"],executionDataTable)
		UIEvents:WaitForChild("PlayerChanged"):FireClient(self.Player,"ExecutionLog")
		return self
	end
end

function PlayerDataTable:LogHistory(player: Player,history: {any}?)
	table.insert(self["GameHistory"],history)
	UIEvents:WaitForChild("PlayerChanged"):FireClient(player,"GameHistory")
	return self
end

function API:RegisterPlayer(player: Player)
	if not player:IsA("Player")	then return nil end
	if Players[player] then return Players[player] end

	local PlayerPolicyInfo, PlayerRegion

	local PolicyFetchSuccess,PolicyFetchError = pcall(function() PlayerPolicyInfo = PolicyService:GetPolicyInfoForPlayerAsync(player) end)
	if not PolicyFetchSuccess then LogError("Failed to get player policy info for",player,":",PolicyFetchError) end

	local RegionFetchSuccess,RegionFetchError = pcall(function() PlayerRegion = LocalizationService:GetCountryRegionForPlayerAsync(player) end)
	if not RegionFetchSuccess then LogError("Failed to get player region for ",player,":",RegionFetchError) end

	--// Player Data

	local NewPlayerDataTable = {
		Username = player.Name, --// Player Username
		UserId = player.UserId, --// Player UserId
		AccountAge = player.AccountAge, --// Player Account Age (how long ago the account was created)
		DisplayName = player.DisplayName, --// Player Display Name
		PermissionLevel = 1, --// Player Permission Level (default = 1)
		JoinTime = os.time(), --// Time player joined game
		PolicyInfo = PolicyService:GetPolicyInfoForPlayerAsync(player), --// Player policy info
		Region = PlayerRegion, --// Player country region
		ExecutionLog = {}, --// Players execution log 
		GameHistory = {}, --// Players game history (used for punishment logging, etc)
		Player = player,
	}

	setmetatable(NewPlayerDataTable,PlayerDataTable)

	--// Set Permission Level

	NewPlayerDataTable:SetPermission()

	--// Data Loading

	local PlayerDataFetchSuccess, PlayerDataFetchData = pcall(function() 
		SolarStore:GetAsync("_"..NewPlayerDataTable.UserId)	
	end)

	if PlayerDataFetchSuccess then
		if PlayerDataFetchData then
			if PlayerDataFetchData.PermissionLevel then
				NewPlayerDataTable.PermissionLevel = PlayerDataFetchData.PermissionLevel
			end
			if PlayerDataFetchData.GameHistory then
				NewPlayerDataTable.GameHistory = PlayerDataFetchData.GameHistory
			end
			if PlayerDataFetchData.ExecutionLog then
				NewPlayerDataTable.ExecutionLog = PlayerDataFetchData.ExecutionLog
			end
		end
	end

	Players[player] = NewPlayerDataTable
	ActionEvents:WaitForChild("PlayerRegistered"):Fire(Players[player])

	--// Insert UI into PlayerGui
	if player:WaitForChild("PlayerGui"):FindFirstChild("SolarUI") == nil then
		local PlayerUI = SolarUI:Clone()
		PlayerUI.Parent = player:WaitForChild("PlayerGui")
	end

	UIEvents:WaitForChild("PlayerRegistered"):FireClient(player)
	local _player: RegisteredPlayer = Players[player]
	return player
end

function API:UnregisterPlayer(player: Player)
	if Players[player] then
		Players[player] = nil
		ActionEvents:WaitForChild("PlayerUnregistered"):Fire(player)
		return true
	end
end

function API:GetPlayers()
	local _players: {[number]: RegisteredPlayer} = Players
	return Players
end

function API:GetPlayer(player: Player | string)

	local fetchedPlayer: RegisteredPlayer | nil

	if type(player) == "string" then
		for _,p in pairs(Players) do
			if string.lower(p.Username) == string.lower(player) then
				fetchedPlayer = p
				return fetchedPlayer
			end
		end
	end
	fetchedPlayer = Players[player]
	return fetchedPlayer
end




--// Hook & Remote Functions





function API:AddHook(name: string,folder: Folder)
	local Hook = Instance.new("BindableEvent")
	Hook.Name = name
	Hook.Parent = folder
	return Hook
end

function API:AddEvent(name: string,folder: Folder)
	local EventListener = Instance.new("RemoteEvent")
	EventListener.Name = name
	EventListener.Parent = folder
	return EventListener
end




--// Command Functions





local CommandObject = {}
CommandObject.__index = CommandObject

export type ReturnObject = {
	success: boolean,
	messages: {
		[number]: string?,
	}
}

function CommandObject:SetName(Name: string)
	self.Name = Name
	return self
end

function CommandObject:SetDescription(Description: string)
	self.Description = Description
	return self
end

function CommandObject:SetPermissionLevel(PermissionLevel: number)
	self.PermissionLevel = PermissionLevel
	return self
end

function CommandObject:AddArgument(Name: string,Type: string,Required: boolean,Options: {})
	table.insert(self.Arguments,{
		Name = Name,
		Type = Type,
		Required = Required,
		Options = Options
	})
	return self
end

function CommandObject:SetOptions(Options: {})
	self.Options = Options
	return self
end

function CommandObject:SetMetadata(Metadata: {LastCompatibleVersion: string,ForceCompatibility: boolean?,[any]: any?})
	if Metadata.LastCompatibleVersion then
		local ver = string.gsub(Metadata.LastCompatibleVersion,"%.","")
		local ver2 = string.gsub(API._version,"%.","")
		ver = tonumber(ver)
		ver2 = tonumber(ver2)
		if ver2 > ver and not Metadata.ForceCompatibility then
			LogError(self.Name,"is outdated and may not work with the latest version of Solar")
		end
	end
	self.Metadata = Metadata
	return self
end

function CommandObject:SetExecuteFunction(callback: (Player: Player,...any) -> ReturnObject?)
	self.Functions.Execute = callback
	return self
end

function CommandObject:SetHook(HookName: string, callback: (...any) -> any)
	self.Hooks[HookName] = callback
	return self
end

function API:CreateReturnObject(success: boolean,... : string)
	local t = {}
	local pt = table.pack(...)	
	pt[5] = nil
	pt["n"] = nil
	for _,s in pairs(pt) do
		local a = string.split(s,"\n")
		for _,ss in pairs(a) do
			table.insert(t,ss)
		end
	end
	print(t)
	return {
		success = success,
		messages = t,
	}
end

function API.CreateCommand()
	local this = {}
	
	this.Name = ""
	this.Description = ""
	this.PermissionLevel = 1
	this.Arguments = {}
	this.Options = {ParseArguments = true,HideExecutionOnClient = false,YieldOnClient = true}
	this.Metadata = {LastCompatibleVersion = API._version,ForceCompatibility = false}
	this.Functions = {
		Execute = function() end
	}
	this.Hooks = {}
	
	setmetatable(this,CommandObject)
	
	return this
end

function API:GetCommands()
	return Commands
end

function API:GetCommand(command: string)
	for _,CommandTable in pairs(Commands) do
		if string.lower(CommandTable.Name) == string.lower(command) then
			return CommandTable
		end
	end
	return nil
end




--// Core Functions





function API:ExecuteCommand(player: Player,command: string,arguments: {any})
	if not player or not command then return nil end
	local RegisteredPlayer = API:GetPlayer(player)
	if not RegisteredPlayer then return end
	local commandTable = API:GetCommand(command)

	if RegisteredPlayer["PermissionLevel"] >= commandTable.PermissionLevel then
		local hasErrored = false
		if (commandTable.ParseArguments or commandTable.ParseArguments == nil) and arguments and #arguments > 0 then
			for argn,arg in ipairs(arguments) do

				if commandTable.Arguments[argn] and commandTable.Arguments[argn].Required == true then
					if tostring(arg) == "" or arg == nil then
						hasErrored = true
						return
					end
				end

				if commandTable.Arguments[argn] ~= nil then
					local commandArgument = commandTable.Arguments[argn]

					if commandArgument.Type == "player" then
						if string.sub(arg,1,1) == "@" then
							if arg == "@me" then
								arguments[argn] = {[1] = API:GetPlayer(player)}
							end
							if arg == "@all" then
								local argumentPlayers = {}
								for _,p in pairs(API:GetPlayers()) do
									table.insert(argumentPlayers,p)
								end
								arguments[argn] = argumentPlayers
							end
							if arg == "@others" then
								local argumentPlayers = {}
								for pi,p in pairs(API:GetPlayers()) do
									if pi.Name ~= player.Name then
										table.insert(argumentPlayers,p)
									end
								end
								arguments[argn] = argumentPlayers
							end
						else
							local GetRegisteredPlayer = API:GetPlayer(arg)
							if commandTable.Arguments[argn].Required == true and not GetRegisteredPlayer then hasErrored = true return end
							if not GetRegisteredPlayer then 
								arguments[argn] = {[1] = nil} 
							else
								arguments[argn] = {[1] = GetRegisteredPlayer}
							end
						end
					end

					if commandArgument.Type == "boolean" then
						if arg == "true" then
							arguments[argn] = true
						else
							arguments[argn] = false
						end
					end

					if commandArgument.Type == "number" then
						if tonumber(arg) == nil then return false end
						arguments[argn] = tonumber(arg)
					end

					if commandArgument.Type == "multistring" then
						local multistratg = table.concat(arguments," ",argn)
						for _,a in pairs(string.split(multistratg," ")) do
							table.remove(arguments,table.find(arguments,a,argn))
						end 
						arguments[argn] = multistratg
					end
				end
			end
		end

		if arguments == nil then arguments = {} end

		if hasErrored == true then
			print(hasErrored)
			return API:CreateReturnObject(false,"Required arguments are missing")
		end

		if commandTable.Hooks["beforeExecute"] then
			commandTable.Hooks["beforeExecute"](RegisteredPlayer,table.unpack(arguments))
		end
		local executed = commandTable.Functions.Execute(RegisteredPlayer,table.unpack(arguments))
		if commandTable.Hooks["afterExecuted"] then
			commandTable.Hooks["afterExecuted"](executed)
		end
		RegisteredPlayer:LogExecution(command,arguments,executed)
		if executed then
			return executed
		else
			LogError("Command does not return valid ReturnObject")
			return false
		end
	else
		return false
	end
end

function API:RegisterCommands(CommandInstances: {ModuleScript})
	for _,CommandModule in pairs(CommandInstances) do
		local module = nil
		local success = pcall(function() module = require(CommandModule) end)
		if not success or not module then LogError("Failed to register",CommandModule) end
		if success and module then
			table.insert(Commands,module)
			if module.Hooks and module.Hooks["onRegister"] then
				module.Hooks["onRegister"](module)
			end
		end
	end
	LogInfo("\nSuccessfuly registered",#Commands," command(s)\nFailed to register",#CommandInstances - #Commands," command(s)")
	return Commands
end

function API:Initialize(RegisterCommandsByDefault: boolean, SettingsModule: ModuleScript?)
	if SettingsModule then Settings = require(SettingsModule) end

	if SolarFolder.Parent ~= game:GetService("ReplicatedStorage") then
		SolarFolder.Parent = game:GetService("ReplicatedStorage")
	end

	if RegisterCommandsByDefault == true or RegisterCommandsByDefault == nil then
		if Settings.RegisterCommandDescendants == true or Settings.RegisterCommandDescendants == nil then
			API:RegisterCommands(CommandsFolder:GetDescendants())
		else
			API:RegisterCommands(CommandsFolder:GetChildren())
		end
	end

	if game:GetService("StarterGui"):FindFirstChild("SolarUI") == nil then
		local SolarUIClone = SolarUI:Clone()
		SolarUIClone.Parent = game:GetService("StarterGui")
	end

	for _,player in pairs(PlayersService:GetPlayers()) do
		local RegisteredPlayer = API:RegisterPlayer(player)
		if RegisteredPlayer == nil then
			LogError("Failed to register player",player)
		else
			ActionEvents:WaitForChild("PlayerRegistered"):Fire(RegisteredPlayer)
		end
	end

	PlayersService.PlayerAdded:Connect(function(player)
		local RegisteredPlayer = API:RegisterPlayer(player)
		if RegisteredPlayer == nil then
			LogError("Failed to register player",player)
		else
			ActionEvents:WaitForChild("PlayerRegistered"):Fire(RegisteredPlayer)
		end
	end)

	PlayersService.PlayerRemoving:Connect(function(player)
		local RegisteredPlayer = API:GetPlayer(player)
		if not RegisteredPlayer then return end

		local DataSaveSuccess = pcall(function() 
			local SaveData = {}
			if Settings.SavedData["PermissionLevel"] == true then
				SaveData["PermissionLevel"] = RegisteredPlayer.PermissionLevel
			end
			if Settings.SavedData["ExecutionLog"] == true then
				SaveData["ExecutionLog"] = RegisteredPlayer.ExecutionLog
			end
			if Settings.SavedData["GameHistory"] == true then
				SaveData["GameHistory"] = RegisteredPlayer.GameHistory
			end
			SolarStore:SetAsync("_"..player.UserId,SaveData)
		end)
		if not DataSaveSuccess then LogError("Failed to save player",player," data") end
		local IsUnregistered = API:UnregisterPlayer(player)
		if IsUnregistered ~= true then
			LogError("Failed to unregister player",player.Name)
		else
			pcall(function() ActionEvents:WaitForChild("PlayerUnregistered"):Fire(RegisteredPlayer) end)
		end
	end)

	UIEvents:WaitForChild("RequestServerCommands").OnServerInvoke = function() 
		return API:GetCommands()		
	end

	UIEvents:WaitForChild("RequestPlayerPermission").OnServerInvoke = function(player)
		local plr = API:GetPlayer(player)
		if plr and plr.PermissionLevel then
			return plr.PermissionLevel
		else
			return nil
		end
	end

	UIEvents:WaitForChild("RequestServerCommand").OnServerInvoke = function(player, command: string) 
		return API:GetCommand(command)
	end

	UIEvents:WaitForChild("RequestCommandExecution").OnServerInvoke = function(player: Player,command: string,arguments: {any})
		if player and command and arguments then
			local result = API:ExecuteCommand(player,command,arguments)
			return result
		end
	end

	coroutine.wrap(function()
		for i, v in pairs(PluginsFolder:GetChildren()) do
			if v:IsA("ModuleScript") then
				local pluginModule = require(v)

				if pluginModule.Type == "client" then
					MiscEvents.PluginClient:FireAllClients(v.Name)
				else
					pluginModule.start()
				end
			end
		end
	end)()
end




--// Return correct APIs





if RunService:IsStudio() then 
	return API
end

if RunService:IsServer() then
	local APIServer = {}
	for i,v in pairs(API) do
		if not ClientAPIs[i] then
			APIServer[i] = v
		end
	end
	return APIServer
end

if RunService:IsClient() then
	local APIClient = {}
	for i,v in pairs(API) do
		if ClientAPIs[i] then
			APIClient[i] = v
		end
		if SharedAPIs[i] then
			APIClient[i] = v
		end
	end
	return APIClient
end
