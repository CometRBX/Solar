--// Autocompletion for Solar Command Bar

--// Client Only

local SolarUIEvents = game:GetService("ReplicatedStorage"):WaitForChild("Solar"):WaitForChild("Events"):WaitForChild("UI")

local PlayerPermission = 1
local Commands = {}
local RequiredCommands = {}

local Autocomplete = {}

local TypeValues = {}

TypeValues["boolean"] = {
	[1] = "true",
	[2] = "false"
}

TypeValues["string"] = {
	[1] = "text",
}

TypeValues["multistring"] = {
	[1] = "some text",
}

TypeValues["number"] = {
	[1] = "1",
}

TypeValues["player"] = {
	[1] = "@all",
	[2] = "@others",
	[3] = "@me",
}

function Autocomplete:FetchCommands()
	return SolarUIEvents:WaitForChild("RequestServerCommands"):InvokeServer()
end

function Autocomplete:FetchPermission()
	return SolarUIEvents:WaitForChild("RequestPlayerPermission"):InvokeServer()
end

function Autocomplete:Initialize()
	Commands = Autocomplete:FetchCommands()
	PlayerPermission = Autocomplete:FetchPermission()
	
	SolarUIEvents:WaitForChild("PlayerChanged").OnClientEvent:Connect(function(ChangedProperty)
		if ChangedProperty == "PermissionLevel" then
			PlayerPermission = Autocomplete:FetchPermission()
		end
	end)
	
	SolarUIEvents:WaitForChild("PlayerRegistered").OnClientEvent:Connect(function()
		PlayerPermission = Autocomplete:FetchPermission()
	end)
	
	SolarUIEvents:WaitForChild("CommandRegistered").OnClientEvent:Connect(function()
		Commands = Autocomplete:FetchCommands()
	end)
end

function Autocomplete:AutocompleteCommand(partialCommand: string,validatePermission: boolean?)
	if partialCommand and type(partialCommand) == "string" and #partialCommand > 0 then
		for _,command in pairs(Commands) do
			if validatePermission == true or validatePermission == nil then
				if PlayerPermission and PlayerPermission >= command.PermissionLevel then
					if string.sub(command.Name,1,string.len(partialCommand)) == partialCommand then
						return command
					end
				end
			else
				if string.sub(command.Name,1,string.len(partialCommand)) == partialCommand then
					return command
				end
			end
			command = nil
		end
	end	
	return nil
end

function Autocomplete:AutocompleteArgument(argumentNumber: number,command: {})
	if argumentNumber and command then
		local arg = command["Arguments"][argumentNumber]
		if not arg then return nil end
		return arg
	end
end

function Autocomplete:AutocompleteArgumentValue(value: string,argumentNumber: number,command: {})
	if value and argumentNumber and command then
		value = string.lower(value)
		local arg = command["Arguments"][argumentNumber]
		if not arg then return nil end
		
		if arg.Type == "string" then
			local suggestions = {}
			for _,v  in ipairs(TypeValues["string"]) do
				if string.sub(v,1,string.len(value)) == value then
					table.insert(suggestions,v)
				end
			end
			return suggestions
			
		elseif arg.Type == "multistring" then
			local suggestions = {}
			for _,v  in ipairs(TypeValues["multistring"]) do
				if string.sub(v,1,string.len(value)) == value then
					table.insert(suggestions,v)
				end
			end
			return suggestions
			
		elseif arg.Type == "number" then
			local suggestions = {}
			for _,v  in ipairs(TypeValues["number"]) do
				if string.sub(v,1,string.len(value)) == value then
					table.insert(suggestions,v)
				end
			end
			return suggestions
			
		elseif arg.Type == "boolean" then
			local suggestions = {}
			for _,v  in ipairs(TypeValues["boolean"]) do
				if string.sub(v,1,string.len(value)) == value then
					table.insert(suggestions,v)
				end
			end
			return suggestions
			
		elseif arg.Type == "player" then
			local suggestions = {}
			for _,v in ipairs(TypeValues["player"]) do
				if string.sub(v,1,string.len(value)) == value then
					table.insert(suggestions,v)
				end
			end

			--if string.len(value) >= 1 then
			for _,v in pairs(game:GetService("Players"):GetPlayers()) do
				if string.sub(string.lower(v.Name),1,string.len(value)) == value then
					table.insert(suggestions,v.Name)
				end
			end
			--end
			return suggestions
			
		end
		
		return nil
	end
end

if game:GetService("RunService"):IsStudio() then
	return Autocomplete
end

if game:GetService("RunService"):IsServer() then
	return {}
end

return Autocomplete
