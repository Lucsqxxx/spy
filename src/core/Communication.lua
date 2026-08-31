type table = {
    [any]: any
}

local Module = {
    CommCallbacks = {}
}

local CommWrapper = {}
CommWrapper.__index = CommWrapper

local SerializeCache = setmetatable({}, {__mode = "k"})
local DeserializeCache = setmetatable({}, {__mode = "k"})

local CoreGui

local Hook
local Channel
local Config
local Process

function Module:Init(Data)

    local Modules = Data.Modules
    local Services = Data.Services

    Hook = Modules.Hook
    Process = Modules.Process
    Config = Modules.Config or Config
    CoreGui = Services.CoreGui
end

function CommWrapper:Fire(...)

    local Queue = self.Queue
    table.insert(Queue, {...})
end

function CommWrapper:ProcessArguments(Arguments)

    local Channel = self.Channel
    Channel:Fire(Process:Unpack(Arguments))
end

function CommWrapper:ProcessQueue()

    local Queue = self.Queue

    for Index = 1, #Queue do
        local Arguments = table.remove(Queue)
        pcall(function()
            self:ProcessArguments(Arguments) 
        end)
    end
end

function CommWrapper:BeginQueueService()

    coroutine.wrap(function()
        while wait() do
            self:ProcessQueue()
        end
    end)()
end

function Module:NewCommWrap(Channel)

    local Base = {
        Queue = setmetatable({}, {__mode = "v"}),
        Channel = Channel,
        Event = Channel.Event
    }

    
    local Wrapped = setmetatable(Base, CommWrapper)
    Wrapped:BeginQueueService()

    return Wrapped
end

function Module:MakeDebugIdHandler()

    
    local Remote = Instance.new("BindableFunction")
    function Remote.OnInvoke(Object)

        return Object:GetDebugId()
    end

    self.DebugIdRemote = Remote
    self.DebugIdInvoke = Remote.Invoke

    return Remote
end

function Module:GetDebugId(Object)

    local Invoke = self.DebugIdInvoke
    local Remote = self.DebugIdRemote
	if not Invoke or not Remote then
		local ok, id = pcall(function()
			return Object:GetDebugId()
		end)
		if ok and id ~= nil then
			return tostring(id)
		end
		return tostring(Object)
	end
	local ok, id = pcall(Invoke, Remote, Object)
	if ok and id ~= nil then
		return tostring(id)
	end
	local ok2, id2 = pcall(function()
		return Object:GetDebugId()
	end)
	if ok2 and id2 ~= nil then
		return tostring(id2)
	end
	return tostring(Object)
end

function Module:GetHiddenParent()

    
    if gethui then return gethui() end
    return CoreGui
end

function Module:CreateCommChannel()

    
    local Force = Config.ForceUseCustomComm
    if create_comm_channel and not Force then
        return create_comm_channel()
    end

    local Parent = self:GetHiddenParent()
    local ChannelId = math.random(1, 10000000)

    
    local Channel = Instance.new("BindableEvent", Parent)
    Channel.Name = ChannelId

    return ChannelId, Channel
end

function Module:GetCommChannel(ChannelId)

    
    local Force = Config.ForceUseCustomComm
    if get_comm_channel and not Force then
        local Channel = get_comm_channel(ChannelId)
        return Channel, false
    end

    local Parent = self:GetHiddenParent()
	if not Parent then
		return nil, true
	end
    local Channel = Parent:FindFirstChild(tostring(ChannelId))
	if not Channel then
		return nil, true
	end
    local Wrapped = self:NewCommWrap(Channel)
    return Wrapped, true
end

local Tick = 0
function Module:WaitCheck()

    Tick += 1
    if Tick > 60 then
        Tick = 0
        task.wait()
    end
end

function Module:SerializeValue(Value, Depth, Seen)

    Depth = Depth or 0
    Seen = Seen or {}
    local ty = typeof(Value)

    if Depth > 10 then
        return { __t = "truncated", reason = "depth" }
    end

    if ty == "nil" then
        return { __t = "nil" }
    elseif ty == "number" or ty == "string" or ty == "boolean" then
        return Value
    elseif ty == "Instance" then
        local ok, full = pcall(function() return Value:GetFullName() end)
        local ok2, cn = pcall(function() return Value.ClassName end)
        return {
            __t = "Instance",
            class = ok2 and cn or "Instance",
            name = tostring(Value),
            path = ok and full or tostring(Value),
        }
    elseif ty == "Vector3" then
        return { __t = "Vector3", x = Value.X, y = Value.Y, z = Value.Z }
    elseif ty == "Vector2" then
        return { __t = "Vector2", x = Value.X, y = Value.Y }
    elseif ty == "CFrame" then
        local x, y, z = Value.X, Value.Y, Value.Z
        return { __t = "CFrame", x = x, y = y, z = z, str = tostring(Value) }
    elseif ty == "Color3" then
        return { __t = "Color3", r = Value.R, g = Value.G, b = Value.B }
    elseif ty == "UDim2" then
        return { __t = "UDim2", str = tostring(Value) }
    elseif ty == "UDim" then
        return { __t = "UDim", scale = Value.Scale, offset = Value.Offset }
    elseif ty == "EnumItem" then
        return { __t = "EnumItem", str = tostring(Value) }
    elseif ty == "buffer" then
        local ok, len = pcall(function() return buffer.len(Value) end)
        return { __t = "buffer", len = ok and len or 0 }
    elseif ty == "function" or ty == "thread" or ty == "userdata" then
        return { __t = ty, str = tostring(Value) }
    elseif ty == "table" then
        if Seen[Value] then
            return { __t = "cycle" }
        end
        Seen[Value] = true
        local Cached = SerializeCache[Value]
        if Cached then return Cached end

        local Serialized = { __t = "table", items = {} }
        SerializeCache[Value] = Serialized
        local n = 0
        for Index, V in next, Value do
            n += 1
            if n > 200 then
                table.insert(Serialized.items, {
                    Index = { __t = "truncated" },
                    Value = { __t = "truncated", reason = "max_entries" },
                })
                break
            end
            self:WaitCheck()
            table.insert(Serialized.items, {
                Index = self:SerializeValue(Index, Depth + 1, Seen),
                Value = self:SerializeValue(V, Depth + 1, Seen),
            })
        end
        return Serialized
    end

    return { __t = ty, str = tostring(Value) }
end

function Module:DeserializeValue(Value)

    if typeof(Value) ~= "table" or Value.__t == nil then
        return Value
    end
    local t = Value.__t
    if t == "nil" then
        return nil
    elseif t == "table" then
        local out = {}
        for _, packet in ipairs(Value.items or {}) do
            local k = self:DeserializeValue(packet.Index)
            local v = self:DeserializeValue(packet.Value)
            if k ~= nil then
                out[k] = v
            end
        end
        return out
    elseif t == "Instance" then
        return Value.path or Value.name or "<Instance>"
    elseif t == "Vector3" then
        return Vector3.new(Value.x, Value.y, Value.z)
    elseif t == "Vector2" then
        return Vector2.new(Value.x, Value.y)
    elseif t == "Color3" then
        return Color3.new(Value.r, Value.g, Value.b)
    elseif t == "cycle" or t == "truncated" then
        return Value
    elseif t == "function" or t == "thread" or t == "userdata" or t == "buffer" then
        return Value.str or ("<" .. t .. ">")
    elseif t == "EnumItem" or t == "CFrame" or t == "UDim2" or t == "UDim" then
        return Value.str or Value
    end
    return Value.str or Value
end

function Module:CheckValue(Value, Inbound)

    if Inbound then
        return self:DeserializeValue(Value)
    end
    if typeof(Value) == "table" and Value.__t then
        return Value
    end
    return self:SerializeValue(Value)
end

function Module:MakePacket(Index, Value)

    self:WaitCheck()
    return {
        Index = self:SerializeValue(Index),
        Value = self:SerializeValue(Value),
    }
end

function Module:ReadPacket(Packet)

    if typeof(Packet) ~= "table" then return Packet end
    local Key = self:DeserializeValue(Packet.Index)
    local Value = self:DeserializeValue(Packet.Value)
    self:WaitCheck()
    return Key, Value
end

function Module:SerializeTable(Table)

    if typeof(Table) ~= "table" then
        return { self:SerializeValue(Table) }
    end
    
    local out = {}
    local maxn = table.maxn(Table)
    if maxn > 0 then
        for i = 1, maxn do
            out[i] = self:SerializeValue(Table[i])
        end
        
        for k, v in next, Table do
            if typeof(k) ~= "number" or k < 1 or k > maxn or k % 1 ~= 0 then
                out[k] = self:SerializeValue(v)
            end
        end
        return out
    end
    return self:SerializeValue(Table)
end

function Module:DeserializeTable(Serialized)

    if typeof(Serialized) ~= "table" then return Serialized end
    if Serialized.__t == "table" then
        return self:DeserializeValue(Serialized)
    end
    local out = {}
    for k, v in next, Serialized do
        out[k] = self:DeserializeValue(v)
    end
    return out
end

function Module:SetChannel(NewChannel)

    Channel = NewChannel
end

function Module:ConsolePrint(...)

    self:Communicate("Print", ...)
end

function Module:QueueLog(Data)

    task.spawn(function()
        local ok, err = pcall(function()
            if Data.Args and not Data.ArgsSerialized then
                Data.Args = self:SerializeTable(Data.Args)
                Data.ArgsSerialized = true
            end
            if Data.ReturnValues ~= nil and typeof(Data.ReturnValues) == "table" and not Data.ReturnsSerialized then
                Data.ReturnValues = self:SerializeTable(Data.ReturnValues)
                Data.ReturnsSerialized = true
            end
            local delivered = false
            pcall(function()
                if Channel then
                    self:Communicate("QueueLog", Data)
                    delivered = true
                end
            end)
            if not delivered then
                local cb = self:GetCommCallback("QueueLog")
                if cb then
                    cb(Data)
                end
            end
        end)
        if not ok then
            warn("[Wyvern Spy] QueueLog error:", err)
        end
    end)
end

function Module:AddCommCallback(Type, Callback)

    local CommCallbacks = self.CommCallbacks
    CommCallbacks[Type] = Callback
end

function Module:GetCommCallback(Type)

    local CommCallbacks = self.CommCallbacks
    return CommCallbacks[Type]
end

function Module:ChannelIndex(Channel, Property)

    if typeof(Channel) == "Instance" then
        return Hook:Index(Channel, Property)
    end

    
    return Channel[Property]
end

function Module:Communicate(...)

    local Fire = self:ChannelIndex(Channel, "Fire")
    local identity = getthreadidentity()
    setthreadidentity(8)
    Fire(Channel, ...)
    setthreadidentity(identity)
end

function Module:AddConnection(Callback)

    local Event = self:ChannelIndex(Channel, "Event")
    return Event:Connect(Callback)
end

function Module:AddTypeCallback(Type, Callback)

    local Event = self:ChannelIndex(Channel, "Event")
    return Event:Connect(function(RecivedType: string, ...)
        if RecivedType ~= Type then return end
        Callback(...)
    end)
end

function Module:AddTypeCallbacks(Types)

    for Type: string, Callback in next, Types do
        self:AddTypeCallback(Type, Callback)
    end
end

function Module:CreateChannel()

    local ChannelID, Event = self:CreateCommChannel()
    -- Must set Channel so QueueLog/Communicate can Fire
    Channel = Event
    self.Channel = Event

    Event.Event:Connect(function(Type: string, ...)
        local Callback = self:GetCommCallback(Type)
        if Callback then
            Callback(...)
        end
    end)

    return ChannelID, Event
end

Module:MakeDebugIdHandler()

return Module
