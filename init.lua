-- privall/init.lua

local storage = minetest.get_mod_storage()

local privall = minetest.deserialize(storage:get_string("data"))

if privall == nil then
	privall = {
		grant = {},
		revoke = {}
	}
end


-- Constants
local green = "#009933"
local red = "#ff3300"

local plus = minetest.colorize(green, " +")
local minus = minetest.colorize(red, " -")

local changedPrefix = "[privall] Your privileges have changed:"


-- Utility functions

local formatOutput = function(prefix, changes)
	local rope = {prefix}
	local changed = false
	
	for _,priv in ipairs(changes.grant) do
		table.insert(rope, plus)
		table.insert(rope, minetest.colorize(green, priv))
		table.insert(rope, ",")
		changed = true
	end

	for _,priv in ipairs(changes.revoke) do
		table.insert(rope, minus)
		table.insert(rope, minetest.colorize(red, priv))
		table.insert(rope, ",")
		changed = true
	end

	return table.concat(rope), changed
end

local save = function()
	storage:set_string("data", minetest.serialize(privall))
end

local isTracked = function(priv)
	return (privall.grant[priv] or privall.revoke[priv])
end

local grantPriv = function(name, priv, changes)
	local privs = minetest.get_player_privs(name)
	if not privs[priv] then
		privs[priv] = true
		minetest.set_player_privs(name, privs)
		table.insert(changes.grant, priv)
		minetest.log("action", "[privall] Granted priv \""..priv.."\" to player \""..name.."\".")
		return true
	end
	return false
end

local revokePriv = function(name, priv, changes)
	local privs = minetest.get_player_privs(name)
	if privs[priv] then
		privs[priv] = nil
		minetest.set_player_privs(name, privs)
		table.insert(changes.revoke, priv)
		minetest.log("action", "[privall] Revoked priv \""..priv.."\" from player \""..name.."\".")
		return true
	end
	return false
end

local grantAll = function(privs)
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local changes = {grant = {}, revoke = {}}
		local changed = false
		for _,priv in ipairs(privs) do
			if grantPriv(name, priv, changes) then
				changed = true
			end
		end
		if changed then
			local text = formatOutput(changedPrefix, changes)
			minetest.chat_send_player(name, text)
		end
	end
end

local revokeAll = function(privs)
	for _,player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local changes = {grant = {}, revoke = {}}
		local changed = false
		for _,priv in ipairs(privs) do
			if revokePriv(name, priv, changes) then
				changed = true
			end
		end
		if changed then
			local text = formatOutput(changedPrefix, changes)
			minetest.chat_send_player(name, text)
		end
	end
end


-- Subcommands

local commands = {
	grant = {
		run = function(name, tokens)
			for _,priv in ipairs(tokens) do
				privall.revoke[priv] = nil
				privall.grant[priv] = true
				minetest.log("action", "[privall] Privilege \""..priv.."\" is now being granted to all players.")
			end
			grantAll(tokens)
			save()
			return true, "[privall] Privileges\""..table.concat(tokens, ", ").."\" are now being granted to all players."
		end,

		checkParams = function(tokens)
			if #tokens == 0 then
				return false, "[privall] Subcommand \"grant\" requires at least 1 argument."
			end
			for _,priv in ipairs(tokens) do
				if not minetest.registered_privileges[priv] then
					return false, "[privall] Unknown privilege \""..priv.."\"."
				end
				if privall.grant[priv] then
					return false, "[privall] Privilege \""..priv.."\" is already being granted to all players."
				end
			end
			return true
		end,
	},
	
	revoke = {
		run = function(name, tokens)
			for _,priv in ipairs(tokens) do
				privall.grant[priv] = nil
				privall.revoke[priv] = true
				minetest.log("action", "[privall] Privilege \""..priv.."\" is now being revoked from all players.")
			end
			revokeAll(tokens)
			save()
			return true, "[privall] Privileges \""..table.concat(tokens, ", ").."\" are now being revoked from all players."
		end,

		checkParams = function(tokens)
			if #tokens == 0 then
				return false, "[privall] Subcommand \"revoke\" requires at least 1 argument."
			end
			for _,priv in ipairs(tokens) do
				if privall.revoke[priv] then
					return false, "[privall] Privilege \""..priv.." is already being revoked from all players."
				end
			end
			return true
		end,
	},

	reset = {
		run = function(name, tokens)
			for _,priv in ipairs(tokens) do
				privall.grant[priv] = nil
				privall.revoke[priv] = nil
				minetest.log("action", "[privall] Cleared assignment for privilege \""..priv.."\".")
			end
			save()
			return true, "[privall] Cleared assignments for privileges \""..table.concat(tokens, ", ").."\"."
		end,

		checkParams = function(tokens)
			if #tokens == 0 then
				return false, "[privall] Subcommand \"reset\" requires at least 1 argument."
			end
			for _,priv in ipairs(tokens) do
				if not isTracked(priv) then
					return false, "[privall] Privilege \""..priv.."\" is not currently tracked by privall."
				end
			end
			return true
		end,
	},

	list = {
		run = function(name, tokens)
			local rope = {"Current privall configuration: "}

			for priv,_ in pairs(privall.grant) do
				table.insert(rope, " +")
				table.insert(rope, priv)
				table.insert(rope, ",")
			end

			for priv,_ in pairs(privall.revoke) do
				table.insert(rope, " -")
				table.insert(rope, priv)
				table.insert(rope, ",")
			end
			if(#rope == 1) then
				table.insert(rope, "None")
			end
			
			minetest.chat_send_player(name, table.concat(rope))
		end,

		checkParams = function(tokens)
			if #tokens ~= 0 then
				return false, "[privall] Subcommand \"list\" takes no arguments."
			end
			return true
		end,
	},
}


-- Hooks

minetest.register_on_shutdown(save)

minetest.register_chatcommand("privall", {
	params = "(grant|revoke|reset|list) <privilege> ...",
	description = "Edit or list the automated granting/revoking of privileges.",
	privs = {privs = true},
	func = function(name, param)
		-- Split params at spaces
		local tokens = {}
		for token in param:gmatch("[^ ]+") do
			table.insert(tokens, token)
		end
		
		-- Sanitize input
		if #tokens == 0 then
			return false, "[privall] Please specify a subcommand. See \"/help privall\" for more details."
		end
		local mode = table.remove(tokens, 1)
		if commands[mode] == nil then
			return false, "[privall] Unknown subcommand \""..mode.."\"."
		end

		-- Check subcommand parameters
		local result, msg = commands[mode].checkParams(tokens)
		if not result then
			return false, msg
		end

		return commands[mode].run(name, tokens)
	end,
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local changes = {grant = {}, revoke = {}}

	for priv,_ in pairs(privall.grant) do
		grantPriv(name, priv, changes)
	end

	for priv,_ in pairs(privall.revoke) do
		revokePriv(name, priv, changes)
	end

	local text, changed = formatOutput(changedPrefix, changes)

	if changed then
		minetest.chat_send_player(name, text)
	end
end)
