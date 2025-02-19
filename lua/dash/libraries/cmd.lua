require 'term'

cmd = cmd or setmetatable({
	GetTable = setmetatable({}, {
		__call = function(self)
			return self
		end
	}),

	OPT_OPTIONAL = 1,

	ERROR_INVALID_COMMAND	= 2, -- command
	ERROR_MISSING_PARAM 	= 3, -- Param #, Param Type
	ERROR_INVALID_PLAYER 	= 4, -- Argument
	ERROR_INVALID_NUMBER 	= 5, -- Argument
	ERROR_INVALID_TIME 		= 6, -- Argument
	ERROR_COMMAND_COOLDOWN 	= 7, -- Seconds left, command

	NumberUnits = {
		h 	= 100,
		k 	= 1000,
		mil = 1000000,
	},

	TimeUnits = {
		mi 	= 60,
		h 	= 3600,
		d 	= 86400,
		w 	= 604800,
		mo 	= 2592000,
		y 	= 31536000
	},

	concommands = {}
}, {
	__call = function(self, name, callback)
		return self.Add(name, callback)
	end,
})

local COMMAND = {
	__tostring = function(self)
		return self.Name
	end
}
COMMAND.__index 			= COMMAND
COMMAND.__concat 			= COMMAND.__tostring
debug.getregistry().Command	= COMMAND

local params = {}

if (SERVER) then
	util.AddNetworkString 'rp.RunCommand'
end

term.Add(cmd.ERROR_MISSING_PARAM, 'Неверный Аргумент #: #')
term.Add(cmd.ERROR_INVALID_PLAYER, 'Неудалось найти данного игрока: #')
term.Add(cmd.ERROR_INVALID_NUMBER, 'Неверное Число: #')
term.Add(cmd.ERROR_INVALID_TIME, 'Не верное время: #')
term.Add(cmd.ERROR_COMMAND_COOLDOWN, 'Вы должны подождать # секунд для того что-бы "#" еще раз!')

-- Arg split
local function splitArgs(cmdobj, args)
	args = args:Trim()

	if (args:len() == 0) then return {} end

	if (cmdobj.SplitQuotes) then
		return string.ExplodeQuotes(args)
	else
		return string.Explode(" ", args)
	end
end

-- Parsing
function cmd.AddParam(name, nicename, parse, autocomplete)
	local id = #params + 1
	cmd[name:upper()] = id
	params[id] = {
		NiceName = nicename,
		Parse = parse,
		AutoComplete = autocomplete
	}
	return id
end

function cmd.Parse(caller, cmdobj, argstring)
	local cmdParams = cmdobj:GetParams()
	local args = splitArgs(cmdobj, argstring)

	local parsed_args = {}
	for k, v in ipairs(cmdParams) do
		if (args[1] == nil) and (not v.Opts[cmd.OPT_OPTIONAL]) then
			hook.Call('cmd.OnCommandError', nil, caller, cmdobj, cmd.ERROR_MISSING_PARAM, {k, params[v.Enum].NiceName})
			return false
		elseif (args[1] ~= nil) then
			local succ, value, used = params[v.Enum].Parse(caller, cmdobj, args[1], args, k)
			if (succ == false) then
				hook.Call('cmd.OnCommandError', nil, caller, cmdobj, value, used)
				return false
			end

			if (hook.Call('cmd.CanParamParse', nil, caller, cmdobj, v.Enum, value) == false) then
				return false
			end

			for i = 1, (used or 1) do
				table.remove(args, 1)
			end

			parsed_args[#parsed_args + 1] = value
		end
	end
	return true, parsed_args
end

-- Defualt parsers
local function playercomplete(cmdobj, arg, args, step)
	local ret = {}
	if (arg ~= nil) and string.IsSteamID32(arg) then
		ret = {arg}
	elseif (arg ~= nil) then
		ret = table.Filter(player.GetAll(), function(v)
			return string.find(v:Name():lower(), arg:lower())
		end)
		if (#ret == 1) then
			ret[1] = ret[1]:SteamID()
		else
			for k, v in ipairs(ret) do
				ret[k] = v:Name()
			end
		end
	else
		for k, v in ipairs(player.GetAll()) do
			ret[#ret + 1] = v:Name()
		end
	end
	return ret
end

cmd.AddParam('PLAYER_STEAMID32', 'Player/SteamID', function(caller, cmdobj, arg, args, step)
	local result = player.Find(arg)
	if (result == nil) and (not string.IsSteamID32(arg)) then
		return false, cmd.ERROR_INVALID_PLAYER, {arg}
	end
	return true, result or arg
end, playercomplete)

cmd.AddParam('PLAYER_STEAMID64', 'Player/SteamID64', function(caller, cmdobj, arg, args, step)
	local result = player.Find(arg)
	if (result == nil) and (not string.IsSteamID64(arg)) then
		return false, cmd.ERROR_INVALID_PLAYER, {arg}
	end
	return true, result or arg
end)

cmd.AddParam('PLAYER_ENTITY', 'Player/SteamID', function(caller, cmdobj, arg, args, step)
	local result = player.Find(arg)
	if (result == nil) then
		return false, cmd.ERROR_INVALID_PLAYER, {arg}
	end
	return true, result
end, playercomplete)

cmd.AddParam('PLAYER_ENTITY_MULTI', 'Players/SteamIDs', function(caller, cmdobj, arg, args, step)
	local results = {}
	for i = 1, ((#args + step) - #cmdobj:GetParams()) do
		local result = player.Find(args[i])
		if (result == nil) then
			return false, cmd.ERROR_INVALID_PLAYER, {args[i]}
		else
			results[#results + 1] = result
		end
	end
	return true, results, #results
end, playercomplete)

cmd.AddParam('WORD', 'Single Word', function(caller, cmdobj, arg, args, step)
	if not arg or arg == '' then
		return false, cmd.ERROR_INVALID_COMMAND, {arg}
	else
		return true, arg
	end
end, function(cmdobj, arg, args, step)
	return {'<Word>'}
end)

cmd.AddParam('STRING', 'String', function(caller, cmdobj, arg, args, step)
	local results = ''
	local c = 0
	for i = 1, ((#args + step) - #cmdobj:GetParams()) do
		results = results .. ((i == 1) and '' or ' ') .. args[i]
		c = c + 1
	end
	return true, results, c
end, function(cmdobj, arg, args, step)
	local results = ''
	local c = 1
	for i = 1, ((#args + step) - #cmdobj:GetParams()) do
		results = results .. ((i == 1) and '' or ' ') .. args[i]
		c = c + 1
	end
	return ((results == '') and {'<String>'} or {results}), c
end)

cmd.AddParam('NUMBER', 'Number', function(caller, cmdobj, arg, args, step)
	local s = 0
	local match = false
	for k, t in string.gmatch(arg:lower(), '(%d+)(%a+)') do
		if cmd.NumberUnits[t] then
			s = s + k * cmd.NumberUnits[t]
			match = true
		else
			return false, cmd.ERROR_INVALID_NUMBER, {arg}
		end
	end
	if (not match) then
		local n = tonumber(arg)
		if (not n) then
			return false, cmd.ERROR_INVALID_NUMBER, {arg}
		end
		return true, n
	end
	return true, s
end, function(cmdobj, arg, args, step)
	if (arg ~= nil) then
		local match = false
		for k, t in string.gmatch(arg:lower(), '(%d+)(%a+)') do
			match = true
			break
		end
		if (not match) then
			if (not tonumber(arg)) then return {'<Number>'} end
			local ret = {}
			for k, v in pairs(cmd.NumberUnits) do
				ret[#ret + 1] = arg .. k
			end
			return ret
		end
	end
	return (arg == nil) and {'<Number>'} or {arg}
end)

cmd.AddParam('TIME', 'Time', function(caller, cmdobj, arg, args, step)
	local s = 0
	for k, t in string.gmatch(arg:lower(), '(%d+)(%a+)') do
		if cmd.TimeUnits[t] then
			s = s + k * cmd.TimeUnits[t]
		else
			return false, cmd.ERROR_INVALID_TIME, {arg}
		end
	end
	if (s == 0) then
		return false, cmd.ERROR_INVALID_TIME, {arg}
	end
	return true, s
end, function(cmdobj, arg, args, step)
	if (arg ~= nil) then
		local match = false
		for k, t in string.gmatch(arg:lower(), '(%d+)(%a+)') do
			if cmd.TimeUnits[t] then
				match = true
				break
			else
				break
			end
		end
		if (not match) then
			if (not tonumber(arg)) then return {'<Time>'} end
			local ret = {}
			for k, v in pairs(cmd.TimeUnits) do
				ret[#ret + 1] = arg .. k
			end
			return ret
		end
	end
	return (arg == nil) and {'<Time>'} or {arg}
end)

cmd.AddParam('RAW', 'Raw', function(called, cmdobj, arg, args, step)
	return true, args, #args
end)


-- Commands
function cmd.Add(name, callback)
	local c = setmetatable({
		Name  		= name:lower():gsub(' ', ''),
		NiceName 	= name,
		Cooldown 	= 0.25,
		SplitQuotes	= false,
		Params		= {},
		CanRun 		= function() end,
		Callback	= callback or function() end
	}, COMMAND)
	cmd.GetTable[c.Name] = c
	return c
end

function cmd.Get(name)
	return cmd.GetTable[name:lower()]
end

function cmd.Exists(name)
	return (cmd.GetTable[name:lower()] ~= nil)
end

function cmd.Remove(name)
	cmd.GetTable[name] = nil
end

if (SERVER) then
	function rp.RunCommand(pl, command, args)
		if cmd.Exists(command) then
			local cmdobj = cmd.Get(command)
			local name = cmdobj:GetName()

			for i = 1, #args do
				if (string.upper(tostring(args[i])) == 'STEAM_0') and (args[i + 4]) then
					args[i] = table.concat(args, '', i, i + 4)
					for _ = 1, 4 do
						table.remove(args, i + 1)
					end
					break
				end
			end

			for k, v in ipairs(args) do
				args[k] = v:sub(1, 126)
			end

			if (hook.Call('cmd.CanRunCommand', nil, pl, cmdobj, args) == false) or (cmdobj:CanRun(pl) == false) then return end

			if pl:IsPlayer() then
				if (not pl.CmdCooldown) then pl.CmdCooldown = {} end

				if pl.CmdCooldown[name] and (pl.CmdCooldown[name] > CurTime()) then
					return hook.Call('cmd.OnCommandError', nil, pl, cmdobj, cmd.ERROR_COMMAND_COOLDOWN, {math.ceil(pl.CmdCooldown[name] - CurTime()), name})
				end
			end

			local succ, parsedargs = cmd.Parse(pl, cmdobj, table.concat(args, ' '))
			if (pl:IsPlayer()) then
				pl:SetCommandCooldown(cmdobj, (succ ~= false) and cmdobj:GetCooldown() or 0.25)
			end

			if (succ ~= false) then
				hook.Call('cmd.OnCommandRun', nil, pl, cmdobj, parsedargs, cmdobj:Run(pl, unpack(parsedargs)))
			end
		end
	end
else
	function rp.RunCommand(command, ...)
		local args = {...}
		net.Start 'rp.RunCommand'
			net.WriteString(command)
			net.WriteUInt(#args, 4)
			for k, v in ipairs(args) do
				net.WriteString(tostring(v))
			end
		net.SendToServer()
	end
end

local PLAYER = FindMetaTable 'Player'
function PLAYER:RunCommand(command, ...)
	rp.RunCommand(self, command, {...})
end

function PLAYER:SetCommandCooldown(cmdobj, time)
	if (not self.CmdCooldown) then self.CmdCooldown = {} end
	self.CmdCooldown[cmdobj:GetName()] = CurTime() + time
end


-- Set
function COMMAND:SetConCommand(name)
	name = name:lower()
	self.ConCommand = name
	if (not cmd.concommands[name]) then
		cmd.concommands[name] = true

		local runcommand
		if (SERVER) then
			runcommand = function(pl, command, args, str)
				command = args[1]
				if (command ~= nil) then
					table.remove(args, 1)
					rp.RunCommand(pl, command, args)
				end
			end
			concommand.Add('_' .. name, runcommand)
		else
			runcommand = function(p, c, a, str) p:ConCommand('_' .. name .. ' ' .. str) end
		end

		concommand.Add(name, runcommand, function(command, str)
			local ret 		= {}
			local args 		= splitArgs(self, str)
			local argcount 	= #args
			local shownext 	= (str:sub(str:len(), str:len() + 1) == ' ') and (argcount >= 1)

			if (argcount <= 1) and (not shownext) then -- We have not decided on a command
				for k, v in pairs(cmd.GetTable()) do
					if (v:GetConCommand() == command) and (v:CanRun(LocalPlayer()) ~= false) and ((not args[1]) or string.StartWith(v:GetName(), args[1]:lower())) then
						ret[#ret + 1] = command .. ' ' .. v:GetName()
					end
				end
				return (#ret > 0) and ret or {'<No results>'}
			end

			if args[1] and cmd.Exists(args[1]) then
				local cmdobj = cmd.Get(args[1])
				table.remove(args, 1)
				command = command .. ' ' .. cmdobj:GetName()

				for k, v in ipairs(cmdobj:GetParams()) do
					if ((not args[1]) and (not shownext)) or (k > argcount) then break end

					local param_ret, used = params[v.Enum].AutoComplete(cmdobj, args[1], args, k)

					if (not param_ret) then break end

					if (#param_ret == 1) then
						ret[1] = (ret[1] or command) .. ' "' .. param_ret[1] .. '"'
					elseif (#param_ret > 1) then
						command = (ret[1] or command)
						ret[1] = nil
						for k, v in ipairs(param_ret) do
							ret[#ret + 1] = command .. ' "' .. v .. '"'
						end
					end

					for i = 1, (used or 1) do
						table.remove(args, i)
					end
					end
			end
			return (#ret > 0) and ret or {'<No results>'}
		end)
	end
	return self
end

function COMMAND:AddParam(param, ...) -- improve this
	-- Convert to quote splitting if we're following up a string with another argument
	if (#self.Params > 0 and self.Params[#self.Params].Enum == cmd.STRING) then
		self.SplitQuotes = true
	end

	local t = {
		Enum = param,
		Opts = {}
	}
	for k, v in ipairs({...}) do
		t.Opts[v] = true
	end
	self.Params[#self.Params + 1] = t
	return self
end

function COMMAND:AddAlias(name)
	cmd.GetTable[name:lower():gsub(' ', '')] = self
	return self
end

function COMMAND:SetCooldown(seconds)
	self.Cooldown = seconds
	return self
end

function COMMAND:RunOnClient(callback)
	self.ClientCallback = callback
	return self
end



-- Get
function COMMAND:GetName()
	return self.Name
end

function COMMAND:GetNiceName()
	return self.NiceName
end

function COMMAND:GetConCommand()
	return self.ConCommand
end

function COMMAND:GetCooldown()
	return self.Cooldown
end

function COMMAND:GetParams()
	return self.Params
end



-- Internal
function COMMAND:Run(caller, ...)
	if caller:IsPlayer() and self.ClientCallback then
		local args = {...}
		net.Start 'rp.RunCommand'
			net.WriteString(self:GetName())
			net.WriteUInt(#args, 4)
			for k, v in ipairs(args) do
				net.WriteType(v)
			end
		net.Send(caller)
	end
	return self.Callback(caller, ...)
end

if (CLIENT) then
	net.Receive('rp.RunCommand', function()
		local args = {}
		local name = net.ReadString()
		for i = 1, net.ReadUInt(4) do
			args[i] = net.ReadType()
		end
		cmd.Get(name).ClientCallback(unpack(args))
	end)
else
	net.Receive('rp.RunCommand', function(len, pl)
		local args = {}
		local command = net.ReadString()
		for i = 1, net.ReadUInt(4) do
			args[#args + 1] = net.ReadString()
		end
		rp.RunCommand(pl, command, args)
	end)

	hook.Add('PlayerSay', 'cmd.PlayerSay', function(pl, text)
		local text = text:Trim()
		if (text[1] == '!') or (text[1] == '/') then
			local args = string.Explode(" ", text)
			local command = args[1]:sub(2)
			table.remove(args, 1)
			rp.RunCommand(pl, command, args)
			return ''
		end
	end)
end