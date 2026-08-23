--[[
	Sigma Spy – Return Spoofs
	Override return values for specific remotes.

	Format:
		[RemoteInstance] = {
			Method = "FireServer" | "InvokeServer" | ...,
			Return = { ... }                    -- static values (unpacked)
			-- or
			Return = function(OriginalFunc, ...) -- dynamic
				return { ... }
			end
		}
]]

return {
	-- Example:
	-- [game.ReplicatedStorage.Remotes.Example] = {
	-- 	Method = "InvokeServer",
	-- 	Return = { "spoofed", 123 },
	-- },
}
