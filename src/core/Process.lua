

type table = {
    [any]: any
}

type RemoteData = {
	Remote: Instance,
    NoBacktrace: boolean?,
	IsReceive: boolean?,
	Args: table,
    Id: string,
	Method: string,
    TransferType: string,
	ValueReplacements: table,
    ReturnValues: table,
    OriginalFunc: (Instance, ...any) -> ...any
}

local Process = {
    
    RemoteClassData = {
        ["RemoteEvent"] = {
            Send = {
                "FireServer",
                "fireServer",
            },
            Receive = {
                "OnClientEvent",
            }
        },
        ["RemoteFunction"] = {
            IsRemoteFunction = true,
            Send = {
                "InvokeServer",
                "invokeServer",
            },
            Receive = {
                "OnClientInvoke",
            }
        },
        ["UnreliableRemoteEvent"] = {
            Send = {
                "FireServer",
                "fireServer",
            },
            Receive = {
                "OnClientEvent",
            }
        },
        ["BindableEvent"] = {
            NoReciveHook = true,
            Send = {
                "Fire",
            },
            Receive = {
                "Event",
            }
        },
        ["BindableFunction"] = {
            IsRemoteFunction = true,
            NoReciveHook = true,
            Send = {
                "Invoke",
            },
            Receive = {
                "OnInvoke",
            }
        }
    },
    RemoteOptions = {},
    LoopingRemotes = {},
    ConfigOverwrites = {
        [{"sirhurt", "potassium", "wave"}] = {
            ForceUseCustomComm = true
        }
    }
}

local Hook
local Communication
local Flags
local ReturnSpoofs
local Ui
local Config

local HttpService: HttpService

local Channel
local WrappedChannel = false

local WyvernENV = getfenv(1)

type Event = RemoteEvent | RemoteFunction | UnreliableRemoteEvent | BindableEvent | BindableFunction
local InstanceCreatedRemotes: typeof(setmetatable({} :: {[Event]: true}, {__mode = "k"})) = setmetatable({}, {
    __mode = "k"
})

function Process:Merge(Base: table, New: table)
    if not New then return end
	for Key, Value in next, New do
		Base[Key] = Value
	end
end

function Process:Init(Data)
    local Modules = Data.Modules
    local Services = Data.Services

    
    HttpService = Services.HttpService

    
    Config = Modules.Config
    Ui = Modules.Ui
    Hook = Modules.Hook
    Communication = Modules.Communication
    ReturnSpoofs = Modules.ReturnSpoofs
    Flags = Modules.Flags

    
    local Configuration = Modules.Configuration
    if Configuration and Configuration.SafeMode then
        return
    end

    local Ok, Err = pcall(function()
        local OldInstancenew
        OldInstancenew = hookfunction(getrenv().Instance.new, newcclosure(function(...)
            local Inst = OldInstancenew(...)
            if typeof(Inst) == "Instance" and Process.RemoteClassData[Inst.ClassName] then
                InstanceCreatedRemotes[Inst :: Event] = true
            end
            return Inst
        end))
    end)
    if not Ok then
        warn("[Wyvern Spy] Instance.new hook skipped:", Err)
    end
end

function Process:SetChannel(NewChannel: BindableEvent, IsWrapped: boolean)
    Channel = NewChannel
    WrappedChannel = IsWrapped
end

function Process:GetConfigOverwrites(Name: string)
    local ConfigOverwrites = self.ConfigOverwrites

    for List, Overwrites in next, ConfigOverwrites do
        if not table.find(List, Name) then continue end
        return Overwrites
    end
    return
end

function Process:CheckConfig(Config: table)
    local Name = identifyexecutor():lower()

    
    local Overwrites = self:GetConfigOverwrites(Name)
    if not Overwrites then return end

    self:Merge(Config, Overwrites)
end

function Process:CleanCError(Error: string)
    Error = Error:gsub(":%d+: ", "")
    Error = Error:gsub(", got %a+", "")
    Error = Error:gsub("invalid argument", "missing argument")
    return Error
end

function Process:CountMatches(String: string, Match: string)
	local Count = 0
	for _ in String:gmatch(Match) do
		Count +=1 
	end

	return Count
end

Process.SnapshotMaxDepth = 8
Process.SnapshotMaxEntries = 200

function Process:CheckValue(Value, Ignore: table?, Cache: table?, Depth: number?)
    local Type = typeof(Value)
    Depth = Depth or 0
    if Communication and Communication.WaitCheck then
        Communication:WaitCheck()
    end

    if Type == "table" then
        Value = self:DeepCloneTable(Value, Ignore, Cache, Depth)
    elseif Type == "Instance" then
        if cloneref then
            Value = cloneref(Value)
        end
    end

    return Value
end

function Process:DeepCloneTable(Table, Ignore: table?, Visited: table?, Depth: number?)
    if typeof(Table) ~= "table" then return Table end
    Depth = Depth or 0
    local MaxDepth = self.SnapshotMaxDepth or 8
    local MaxEntries = self.SnapshotMaxEntries or 200
    local Cache = Visited or {}

    if Cache[Table] then
        return Cache[Table]
    end

    if Depth >= MaxDepth then
        return { __wyvern = "max_depth", depth = Depth }
    end

    local New = {}
    Cache[Table] = New

    local count = 0
    for Key, Value in next, Table do
        count += 1
        if count > MaxEntries then
            New.__wyvern_truncated = true
            New.__wyvern_count = count
            break
        end
        if Ignore and table.find(Ignore, Value) then
            continue
        end
        local NewKey = self:CheckValue(Key, Ignore, Cache, Depth + 1)
        New[NewKey] = self:CheckValue(Value, Ignore, Cache, Depth + 1)
    end

    if not Visited then
        table.clear(Cache)
    end

    return New
end

function Process:SnapshotArgs(...)
    local packed = { ... }
    return self:DeepCloneTable(packed)
end

function Process:ArgFingerprint(Method: string, Args: table)
    local parts = { tostring(Method) }
    local n = math.min(table.maxn(Args), 6)
    for i = 1, n do
        local v = Args[i]
        local ty = typeof(v)
        if ty == "string" then
            parts[#parts + 1] = "s:" .. string.sub(v, 1, 32)
        elseif ty == "number" or ty == "boolean" then
            parts[#parts + 1] = ty:sub(1, 1) .. ":" .. tostring(v)
        elseif ty == "Instance" then
            parts[#parts + 1] = "i:" .. tostring(v)
        elseif ty == "table" then
            parts[#parts + 1] = "t:" .. tostring(table.maxn(v))
        else
            parts[#parts + 1] = ty
        end
    end
    return table.concat(parts, "|")
end

function Process:Unpack(Table: table)
    if not Table then return Table end
	local Length = table.maxn(Table)
	return unpack(Table, 1, Length)
end

function Process:PushConfig(Overwrites)
    self:Merge(self, Overwrites)
end

function Process:FuncExists(Name: string)
	return WyvernENV[Name]
end

function Process:CheckExecutor()
    local Blacklisted = {
        "xeno",
        "solara",
        "jjsploit"
    }

    local Name = identifyexecutor():lower()
    local IsBlacklisted = table.find(Blacklisted, Name)

    
    if IsBlacklisted then
        Ui:ShowUnsupportedExecutor(Name)
        return false
    end

    return true
end

function Process:CheckFunctions()
    local CoreFunctions = {
        "hookmetamethod",
        "hookfunction",
        "getrawmetatable",
        "setreadonly"
    }

    
    for _, Name in CoreFunctions do
        local Func = self:FuncExists(Name)
        if Func then continue end

        
        Ui:ShowUnsupported(Name)
        return false
    end

    return true
end

function Process:CheckIsSupported()
    
    local ExecutorSupported = self:CheckExecutor()
    if not ExecutorSupported then
        return false
    end

    
    local FunctionsSupported = self:CheckFunctions()
    if not FunctionsSupported then
        return false
    end

    return true
end

function Process:GetClassData(Remote: Instance)
	if typeof(Remote) ~= "Instance" then return nil end
    local RemoteClassData = self.RemoteClassData
    local ClassName = Hook:Index(Remote, "ClassName")

    return RemoteClassData[ClassName]
end

function Process:IsProtectedRemote(Remote: Instance)
    local IsDebug = Remote == Communication.DebugIdRemote
    local IsChannel = Remote == (WrappedChannel and Channel.Channel or Channel)

    return IsDebug or IsChannel
end

function Process:RemoteAllowed(Remote: Event, TransferType: string, Method: string?)
    if typeof(Remote) ~= 'Instance' or InstanceCreatedRemotes[Remote] then return end
    
    
    if self:IsProtectedRemote(Remote) then return end

    
	local ClassData = self:GetClassData(Remote)
	if not ClassData then return end

    
	local Allowed = ClassData[TransferType]
	if not Allowed then return end

    
	if Method then
		return table.find(Allowed, Method) ~= nil
	end

	return true
end

function Process:SetExtraData(Data: table)
    if not Data then return end
    self.ExtraData = Data
end

function Process:GetRemoteSpoof(Remote: Instance, Method: string, ...)
    local Spoof = ReturnSpoofs[Remote]

    if not Spoof then return end
    if Spoof.Method ~= Method then return end

    local ReturnValues = Spoof.Return

    
    if typeof(ReturnValues) == "function" then
        ReturnValues = ReturnValues(...)
    end

	return ReturnValues
end

function Process:SetNewReturnSpoofs(NewReturnSpoofs: table)
    ReturnSpoofs = NewReturnSpoofs
end

function Process:FindCallingLClosure(Offset: number)
    local Getfenv = Hook:GetOriginalFunc(getfenv)
    Offset += 1

    while true do
        Offset += 1

        
        local IsValid = debug.info(Offset, "l") ~= -1
        if not IsValid then continue end

        
        local Function = debug.info(Offset, "f")
        if not Function then return end
        if Getfenv(Function) == WyvernENV then continue end

        return Function
    end
end

function Process:Decompile(Script: LocalScript | ModuleScript)
    local KonstantAPI = "http://api.plusgiant5.com/konstant/decompile"
    local ForceKonstant = Config.ForceKonstantDecompiler

    
    if decompile and not ForceKonstant then 
        return decompile(Script)
    end

    
    local Success, Bytecode = pcall(getscriptbytecode, Script)
    if not Success then
        local Error = "-- Failed to get script bytecode\n" .. tostring(Bytecode)
        return Error, true
    end
    
    
    local Responce = request({
        Url = KonstantAPI,
        Body = Bytecode,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "text/plain"
        },
    })

    
    if Responce.StatusCode ~= 200 then
        local Error = "-- Konstant decompile failed: HTTP " .. tostring(Responce.StatusCode)
        return Error, true
    end

    return Responce.Body
end

function Process:GetScriptFromFunc(Func: (...any) -> ...any)
    if not Func then return end

    local Success, ENV = pcall(getfenv, Func)
    if not Success then return end
    
    
    if self:IsWyvernSpyENV(ENV) then return end

    return rawget(ENV, "script")
end

function Process:ConnectionIsValid(Connection: table)
    local ValueReplacements = {
		["Script"] = function(Connection: table): Script?
			local Function = Connection.Function
			if not Function then return end

			return self:GetScriptFromFunc(Function)
		end
	}

    
    local ToCheck = {
        "Script"
    }
    for _, Property in ToCheck do
        local Replacement = ValueReplacements[Property]
        local Value

        
        if Replacement then
            Value = Replacement(Connection)
        end

        
        if Value == nil then 
            return false 
        end
    end

    return true
end

function Process:FilterConnections(Signal: RBXScriptSignal)
    local Processed = {}

    
    for _, Connection in getconnections(Signal) do
        if not self:ConnectionIsValid(Connection) then continue end
        table.insert(Processed, Connection)
    end

    return Processed
end

function Process:IsWyvernSpyENV(Env: table)
    return Env == WyvernENV
end

function Process:GetRemoteData(Id: string)
    local RemoteOptions = self.RemoteOptions
	if Id == nil then
		return { Excluded = false, Blocked = false }
	end

	local Existing = RemoteOptions[Id]
	if Existing then return Existing end

	local Data = {
		Excluded = false,
		Blocked = false
	}

	RemoteOptions[Id] = Data
	return Data
end

function Process:CallDiscordRPC(Body: table)
    request({
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Origin"] = "https://discord.com/"
        },
        Body = HttpService:JSONEncode(Body)
    })
end

function Process:PromptDiscordInvite(InviteCode: string)
    self:CallDiscordRPC({
        cmd = "INVITE_BROWSER",
        nonce = HttpService:GenerateGUID(false),
        args = {
            code = InviteCode
        }
    })
end

local ProcessCallback = newcclosure(function(Data: RemoteData, Remote, ...): table?
    local OriginalFunc = Data.OriginalFunc
    local Id = Data.Id
    local Method = Data.Method

    if Id ~= nil then
        local RemoteData = Process:GetRemoteData(Id)
        if RemoteData and RemoteData.Blocked then
            return {}
        end
    end

    local Spoof = Process:GetRemoteSpoof(Remote, Method, OriginalFunc, ...)
    if Spoof then return Spoof end

    if not OriginalFunc then
        return nil
    end

    return {
        OriginalFunc(Remote, ...)
    }
end)

function Process:ProcessRemote(Data: RemoteData, Remote, ...)
	local Method = Data.Method
    local TransferType = Data.TransferType
    local IsReceive = Data.IsReceive

	if TransferType and not self:RemoteAllowed(Remote, TransferType, Method) then return end

	
	local Id = Data.Id
	if Id == nil and Communication and Communication.GetDebugId then
		local ok, got = pcall(function()
			return Communication:GetDebugId(Remote)
		end)
		if ok then
			Id = got
			Data.Id = Id
		end
	end

	
	local SkipLog = false
	if Flags and Flags.GetFlagValue then
		local ok, paused = pcall(function() return Flags:GetFlagValue("Paused") end)
		if ok and paused then
			SkipLog = true
		end
		if not SkipLog and IsReceive then
			local ok2, logRecv = pcall(function() return Flags:GetFlagValue("LogRecives") end)
			if ok2 and logRecv == false then
				SkipLog = true
			end
		end
		if not SkipLog and Data.IsExploit then
			local ok3, logEx = pcall(function() return Flags:GetFlagValue("LogExploit") end)
			if ok3 and logEx == false then
				SkipLog = true
			end
		end
	end

	local ExtraData = self.ExtraData
	if ExtraData then
		self:Merge(Data, ExtraData)
	end

	local ReturnValues = ProcessCallback(Data, Remote, ...)
	Data.ReturnValues = ReturnValues

	if SkipLog then
		return ReturnValues
	end

	
	local ClassData = self:GetClassData(Remote)
	local Timestamp = tick()

	local CallingFunction
	local SourceScript
	if not IsReceive then
		CallingFunction = self:FindCallingLClosure(6)
		SourceScript = CallingFunction and self:GetScriptFromFunc(CallingFunction) or nil
	end

	local ArgsSnap = self:SnapshotArgs(...)
	local Fingerprint = self:ArgFingerprint(Method or "?", ArgsSnap)

	self:Merge(Data, {
		Remote = cloneref and cloneref(Remote) or Remote,
		CallingScript = getcallingscript and getcallingscript() or nil,
		CallingFunction = CallingFunction,
		SourceScript = SourceScript,
		Id = Id,
		ClassData = ClassData,
		Timestamp = Timestamp,
		Args = ArgsSnap,
		ArgsSnapshot = true,
		Fingerprint = Fingerprint,
		RemotePath = (function()
			local ok, name = pcall(function() return Remote:GetFullName() end)
			return ok and name or tostring(Remote)
		end)(),
	})

	Communication:QueueLog(Data)
	return ReturnValues
end

function Process:SetAllRemoteData(Key: string, Value)
    local RemoteOptions = self.RemoteOptions
	for RemoteID, Data in next, RemoteOptions do
		Data[Key] = Value
	end
end

function Process:SetRemoteData(Id: string, RemoteData: table)
    local RemoteOptions = self.RemoteOptions
    RemoteOptions[Id] = RemoteData
end

function Process:UpdateRemoteData(Id: string, RemoteData: table)
    Communication:Communicate("RemoteData", Id, RemoteData)
end

function Process:UpdateAllRemoteData(Key: string, Value)
    Communication:Communicate("AllRemoteData", Key, Value)
end

return Process
