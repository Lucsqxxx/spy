

local Hook = {
	OriginalNamecall = nil,
	OriginalIndex = nil,
	PreviousFunctions = {},
	DefaultConfig = {
		FunctionPatches = true
	}
}

type table = {
	[any]: any
}

type MetaFunc = (Instance, ...any) -> ...any
type UnkFunc = (...any) -> ...any

local Modules
local Process
local Configuration
local Config
local Communication

local ExeENV = getfenv(1)

function Hook:Init(Data)

    Modules = Data.Modules

	Process = Modules.Process
	Communication = Modules.Communication or Communication
	Config = Modules.Config or Config
	Configuration = Modules.Configuration or Configuration
end

local HookMiddle = newcclosure(function(OriginalFunc, Callback, AlwaysTable: boolean?, ...)
	
	local ReturnValues = Callback(...)
	if ReturnValues then
		
		if not AlwaysTable then
			return Process:Unpack(ReturnValues)
		end

		
		return ReturnValues
	end

	
	if AlwaysTable then
		return {OriginalFunc(...)}
	end

	
	return OriginalFunc(...)
end)

local function Merge(Base, New)

	for Key, Value in next, New do
		Base[Key] = Value
	end
end

function Hook:Index(Object, Key)

    local identity = getthreadidentity()
    setthreadidentity(8)
    local returned = Object[Key]
    setthreadidentity(identity)
	return returned
end

function Hook:PushConfig(Overwrites)

    Merge(self, Overwrites)
end

function Hook:ReplaceMetaMethod(Object, Call, Callback)

	local Metatable = getrawmetatable(Object)
	local OriginalFunc = clonefunction(Metatable[Call])
	
	
	setreadonly(Metatable, false)
	Metatable[Call] = newcclosure(function(...)
		return HookMiddle(OriginalFunc, Callback, false, ...)
	end)
	setreadonly(Metatable, true)

	return OriginalFunc
end

function Hook:HookFunction(Func, Callback)

	local OriginalFunc
	local WrappedCallback = newcclosure(Callback)
	OriginalFunc = clonefunction(hookfunction(Func, function(...)
		return HookMiddle(OriginalFunc, WrappedCallback, false, ...)
	end))
	return OriginalFunc
end

function Hook:HookMetaCall(Object, Call, Callback)

	local Metatable = getrawmetatable(Object)
	local Unhooked
	
	Unhooked = self:HookFunction(Metatable[Call], function(...)
		return HookMiddle(Unhooked, Callback, true, ...)
	end)
	return Unhooked
end

function Hook:HookMetaMethod(Object, Call, Callback)

	local Func = newcclosure(Callback)
	
	
	if Config.ReplaceMetaCallFunc then
		return self:ReplaceMetaMethod(Object, Call, Func)
	end
	
	
	return self:HookMetaCall(Object, Call, Func)
end

function Hook:PatchFunctions()

	
	if Config.NoFunctionPatching then return end

	local Patches = {
		
		
		[pcall] =  function(OldFunc, Func, ...)
			local Responce = {OldFunc(Func, ...)}
			local Success, Error = Responce[1], Responce[2]
			local IsC = iscclosure(Func)

			
			if Success == false and IsC then
				local NewError = Process:CleanCError(Error)
				Responce[2] = NewError
			end

			
			if Success == false and not IsC and Error:find("C stack overflow") then
				local Tracetable = Error:split(":")
				local Caller, Line = Tracetable[1], Tracetable[2]
				local Count = Process:CountMatches(Error, Caller)

				if Count == 196 then
					Communication:ConsolePrint(`C stack overflow patched, count was {Count}`)
					Responce[2] = Error:gsub(`{Caller}:{Line}: `, Caller, 1)
				end
			end

			return Responce
		end,
		[getfenv] = function(OldFunc, Level: number, ...)
			Level = Level or 1

			
			if type(Level) == "number" then
				Level += 2
			end

			local Responce = {OldFunc(Level, ...)}
			local ENV = Responce[1]

			
			if not checkcaller() and ENV == ExeENV then
				Communication:ConsolePrint("ENV escape patched")
				return OldFunc(999999, ...)
			end

			return Responce
		end
	}

	
	for Func, CallBack in Patches do
		local Wrapped = newcclosure(CallBack)
		local OldFunc; OldFunc = self:HookFunction(Func, function(...)
			return Wrapped(OldFunc, ...)
		end)

		
		self.PreviousFunctions[Func] = OldFunc
	end
end

function Hook:GetOriginalFunc(Func)

	return self.PreviousFunctions[Func] or Func
end

function Hook:RunOnActors(Code, ChannelId)

	if not getactors or not run_on_actor then return end
	
	local Actors = getactors()
	if not Actors then return end
	
	for _, Actor in Actors do 
		pcall(run_on_actor, Actor, Code, ChannelId)
	end
end

local function ProcessRemote(OriginalFunc, MetaMethod, self, Method, ...)

	return Process:ProcessRemote({
		Method = Method,
		OriginalFunc = OriginalFunc,
		MetaMethod = MetaMethod,
		TransferType = "Send",
		IsExploit = checkcaller()
	}, self, ...)
end

function Hook:HookRemoteTypeIndex(ClassName, FuncName)

	local Remote = Instance.new(ClassName)
	local Func = Remote[FuncName]
	local OriginalFunc

	
	
	
	
	OriginalFunc = self:HookFunction(Func, function(self, ...)
		
		if not Process:RemoteAllowed(self, "Send", FuncName) then return end

		
		return ProcessRemote(OriginalFunc, "__index", self, FuncName, ...)
	end)
end

function Hook:HookRemoteIndexes()

	
	local RemoteClassData = Process.RemoteClassData
	local Seen = {}
	for ClassName, Data in RemoteClassData do
		for _, FuncName in Data.Send do
			local key = ClassName .. "." .. FuncName
			if not Seen[key] then
				Seen[key] = true
				pcall(function()
					self:HookRemoteTypeIndex(ClassName, FuncName)
				end)
			end
		end
	end
end

function Hook:BeginHooks()

	
	self:HookRemoteIndexes()

	
	local OriginalNameCall
	OriginalNameCall = self:HookMetaMethod(game, "__namecall", function(self, ...)
		local Method = getnamecallmethod()
		return ProcessRemote(OriginalNameCall, "__namecall", self, Method, ...)
	end)

	Merge(self, {
		OriginalNamecall = OriginalNameCall,
		
	})
end

function Hook:HookClientInvoke(Remote, Method, Callback)

	local Success, Function = pcall(function()
		return getcallbackvalue(Remote, Method)
	end)

	
	if not Success then return end
	if not Function then return end
	
	
	local HookSuccess = pcall(function()
		self:HookFunction(Function, Callback)
	end)
	if HookSuccess then return end

	
	Remote[Method] = function(...)
		return HookMiddle(Function, Callback, false, ...)
	end
end

function Hook:MultiConnect(Remotes)

	for _, Remote in next, Remotes do
		self:ConnectClientRecive(Remote)
	end
end

function Hook:ConnectClientRecive(Remote)

	local Allowed = Process:RemoteAllowed(Remote, "Receive")
	if not Allowed then return end

    local ClassData = Process:GetClassData(Remote)
	if not ClassData or not ClassData.Receive then
		return
	end
    local IsRemoteFunction = ClassData.IsRemoteFunction
	local NoReciveHook = ClassData.NoReciveHook
    local Method = ClassData.Receive[1]
	if not Method then return end

	if NoReciveHook then return end

	
	local function Callback(...)

        return Process:ProcessRemote({
            Method = Method,
            IsReceive = true,
            MetaMethod = "Connect",
			IsExploit = checkcaller()
        }, Remote, ...)
	end

	
	if not IsRemoteFunction then
   		Remote[Method]:Connect(Callback)
	else 
		self:HookClientInvoke(Remote, Method, Callback)
	end
end

function Hook:BeginService(Libraries, ExtraData, ChannelId, ...)

	
	local ReturnSpoofs = Libraries.ReturnSpoofs
	local ProcessLib = Libraries.Process
	local Communication = Libraries.Communication
	local Generation = Libraries.Generation
	local Config = Libraries.Config

	
	ProcessLib:CheckConfig(Config)

	
	local InitData = {
		Modules = {
			ReturnSpoofs = ReturnSpoofs,
			Generation = Generation,
			Communication = Communication,
			Process = ProcessLib,
			Config = Config,
			Hook = self,
			Flags = Libraries.Flags or (Modules and Modules.Flags),
			Ui = Libraries.Ui or (Modules and Modules.Ui),
			Configuration = Libraries.Configuration or (Modules and Modules.Configuration),
		},
		Services = setmetatable({}, {
			__index = function(self, Name: string)
				local Service = game:GetService(Name)
				return cloneref(Service)
			end,
		})
	}

	
	Communication:Init(InitData)
	ProcessLib:Init(InitData)

	
	local Channel, IsWrapped = Communication:GetCommChannel(ChannelId)
	Communication:SetChannel(Channel)
	Communication:AddTypeCallbacks({
		["RemoteData"] = function(Id: string, RemoteData)
			ProcessLib:SetRemoteData(Id, RemoteData)
		end,
		["AllRemoteData"] = function(Key: string, Value)
			ProcessLib:SetAllRemoteData(Key, Value)
		end,
		["UpdateSpoofs"] = function(Content: string)
			local Spoofs = loadstring(Content)()
			ProcessLib:SetNewReturnSpoofs(Spoofs)
		end,
		["BeginHooks"] = function(Config)
			if Config.PatchFunctions then
				self:PatchFunctions()
			end
			self:BeginHooks()
			Communication:ConsolePrint("Hooks loaded")
		end
	})
	
	
	ProcessLib:SetChannel(Channel, IsWrapped)
	ProcessLib:SetExtraData(ExtraData)

	
	self:Init(InitData)

	if ExtraData and ExtraData.IsActor then
		Communication:ConsolePrint("Actor connected!")
	end
end

function Hook:LoadMetaHooks(ActorCode, ChannelId)

	
	if not Configuration.NoActors then
		self:RunOnActors(ActorCode, ChannelId)
	end

	
	self:BeginService(Modules, nil, ChannelId) 
end

function Hook:LoadReceiveHooks()

	local NoReceiveHooking = Config.NoReceiveHooking
	local BlackListedServices = Config.BlackListedServices or {}

	if NoReceiveHooking then return end

	
	pcall(function()
		game.DescendantAdded:Connect(function(Remote)
			pcall(function()
				self:ConnectClientRecive(Remote)
			end)
		end)
	end)

	
	pcall(function()
		if getnilinstances then
			self:MultiConnect(getnilinstances())
		end
	end)

	
	local Preferred = {
		"ReplicatedStorage",
		"ReplicatedFirst",
		"Players",
		"Workspace",
	}
	for _, ServiceName in Preferred do
		pcall(function()
			local Service = game:GetService(ServiceName)
			if table.find(BlackListedServices, Service.ClassName) then return end
			self:MultiConnect(Service:GetDescendants())
		end)
	end
end

function Hook:LoadHooks(ActorCode, ChannelId)

	local Ok, Err = pcall(function()
		self:LoadMetaHooks(ActorCode, ChannelId)
	end)
	if not Ok then
		warn("[Wyvern Spy] LoadMetaHooks error:", Err)
	end

	Ok, Err = pcall(function()
		self:LoadReceiveHooks()
	end)
	if not Ok then
		warn("[Wyvern Spy] LoadReceiveHooks error:", Err)
	end
end

return Hook
