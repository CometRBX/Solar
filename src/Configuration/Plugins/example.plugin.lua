local Plugin = {
	Name = "Example Plugin",
	Type = "client", --// 'client' will run the plugin on the client-side and 'server' will run the plugin on the server-side
}

function Plugin.start()
	print("Hello! I'm a plugin :)")
end

return Plugin
