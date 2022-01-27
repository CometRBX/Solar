local API = require(game:GetService("ReplicatedStorage"):WaitForChild("Solar"):WaitForChild("API"))

local Command = API.CreateCommand()
:SetName("example") --// Name of your command
:SetDescription("This is an example command") --// Description of your command
:SetPermissionLevel(4) --// Permission level of your command
:AddArgument("arg1","string",true) --// Command Argument (name,type,required)
:AddArgument("arg2","player",false) --// Command Argument 2 (name,type,required)
:SetOptions({ --// Command Options
	ParseArguments = true, --// Should arguments be parsed to their correct types or should they be sent as strings
	HideExecutionOnClient = false, --// Should command execution be hidden on the client?
	YieldOnClient = false, --// Should the client wait for this command to execute before closing
})
:SetMetadata({ --// Command Metadata
	LastCompatibleVersion = "0.3.3", --// Which version of Solar is this command compatible with
	ForceCompatibility = false, --// Should the module display an error when this command is outdated
})

Command:SetExecuteFunction(function(Player: API.RegisteredPlayer,arg1: string,arg2: {[number]: API.RegisteredPlayer}) --// Function to run when this command is executed
	print("Command executed, arguments: ",Player,arg1,arg2)
	return API:CreateReturnObject(true,"Hello from this command!")
end)

Command:SetHook("onRegister",function(Command)  --// Function which runs when this hook has been fired (hook name, callback)
	print("example has been registered!")
end)

return Command
