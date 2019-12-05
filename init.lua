-- privafk/init.lua

local storage = minetest.get_mod_storage()

local privafk = minetest.deserialize(storage:get_string("data"))

if privafk == nil then
	privafk = {
		grant = {},
		revoke = {}
	}
end


-- Constants
local green = "#009933"
local red = "#ff3300"
local plus = minetest.colorize(green, " +")
local minus = minetest.colorize(red, " -")


-- Utility functions

local grantPriv = function(name, priv, noMsg)
	noMsg = noMsg or false
	local privs = minetest.get_player_privs(name)
	if not privs[priv] then
		privs[priv] = true
		minetest.set_player_privs(name, privs)
		if not noMsg then
			minetest.chat_send_player(name, minetest.colorize(green, "[privafk] You have been granted the privilege \""..priv.."\"."))
		end
		minetest.log("action", "[privafk] Granted priv \""..priv.."\" to player \""..name.."\".")
		return true
	end
	return false
end

local revokePriv = function(name, priv, noMsg)
	noMsg = noMsg or false
	local privs = minetest.get_player_privs(name)
	if privs[priv] then
		privs[priv] = nil
		minetest.set_player_privs(name, privs)
		if not noMsg then
			minetest.chat_send_player(name, minetest.colorize(red, "[privafk] You have lost the privilege \""..priv.."\"."))
		end
		minetest.log("action", "[privafk] Revoked priv \""..priv.."\" from player \""..name.."\".")
		return true
	end
	return false
end

local save = function()
	storage:set_string("data", minetest.serialize(privafk))
end


-- Chat commands

local commands = {
	grant = function(priv)
		if privafk.grant[priv] then
			return "\""..priv.."\" is already auto granted."
		end
		if privafk.revoke[priv] then
			privafk.revoke[priv] = nil
		end
		privafk.grant[priv] = true
		for _,player in ipairs(minetest.get_connected_players()) do
			grantPriv(player:get_player_name(), priv)
		end
		minetest.log("action", "[privafk] Privilege \""..priv.."\" will now be granted to all players.")
		return "\""..priv.."\" will now be granted to all players."
	end,

	revoke = function(priv)
		if privafk.revoke[priv] then
			return "\""..priv.."\" is already auto revoked."
		end
		if privafk.grant[priv] then
			privafk.grant[priv] = nil
		end
		privafk.revoke[priv] = true
		for _,player in ipairs(minetest.get_connected_players()) do
			revokePriv(player:get_player_name(), priv)
		end
		minetest.log("action", "[privafk] Privilege \""..priv.."\" will now be revoked from all players.")
		return "\""..priv.."\" will now be revoked for all players."
	end,

	reset = function(priv)
		privafk.grant[priv] = nil
		privafk.revoke[priv] = nil
		minetest.log("action", "[privafk] Cleared assignment for privilege \""..priv.."\".")
		return "Removed auto assignment of \""..priv.."\"."
	end,

	list = function()
		local rope = {"Current privafk configuration: "}
		-- Grant
		for priv,_ in pairs(privafk.grant) do
			table.insert(rope, " +")
			table.insert(rope, priv)
			table.insert(rope, ",")
		end

		for priv,_ in pairs(privafk.revoke) do
			table.insert(rope, " -")
			table.insert(rope, priv)
			table.insert(rope, ",")
		end
		if(#rope == 1) then
			table.insert(rope, "None")
		end
		return table.concat(rope)
	end,
}


-- Hooks

minetest.register_on_shutdown(save)

minetest.register_chatcommand("privafk", {
	params = "(grant|revoke|reset|list) <privilege>",
	description = "Setup or remove an automated grant/revoke of player privileges.",
	privs = {privs = true},
	func = function(name, param)
		local tokens = {}		
		for token in param:gmatch("[^ ]+") do
			table.insert(tokens, token)
		end
		local mode = tokens[1] or ""
		local priv = tokens[2] or ""
		if commands[mode] == nil then
			return false, "Subcommand \"" ..mode.. "\" does not exists."	
		end
		if (mode ~= "list") and not core.registered_privileges[priv] then
			if(priv == "") then
				return false, "Missing argument."
			end
			return false, "Unknown privilege \""..priv.."\"."
		end
		local result = commands[mode](priv)
		save()
		return true, result
	end,
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local rope = {"[privafk] Your privileges have changed:"}
	local changed = false

	-- Grant privs
	for priv,_ in pairs(privafk.grant) do
		if grantPriv(name, priv, true) then
			table.insert(rope, plus)
			table.insert(rope, minetest.colorize(green, priv))
			changed = true
		end
	end

	-- Revoke privs
	for priv,_ in pairs(privafk.revoke) do
		if revokePriv(name, priv, true) then
			table.insert(rope, minus)
			table.insert(rope, minetest.colorize(red, priv))
			changed = true
		end
	end

	if changed then
		rope = table.concat(rope)
		minetest.chat_send_player(name, rope)
	end
end)
