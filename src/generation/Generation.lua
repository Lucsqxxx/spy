-- wyvern gen 2026-08-26b
type table = {
	[any]: any
}

type RemoteData = {
	Remote: Instance,
	IsReceive: boolean?,
	MetaMethod: string,
	Args: table,
	Method: string,
    TransferType: string,
	ValueReplacements: table,
	NoVariables: boolean?
}

local Generation = {
	DumpBaseName = "WyvernSpy-Dump %s.lua",
	Header = "-- Generated with Wyvern Spy\n",
	ScriptTemplates = {
		["Remote"] = {
			{"%RemoteCall%"}
		},
		["Minimal"] = {
			{"%RemoteCall%"}
		},
		["Edit"] = {
			{"-- Edit args, then press Run"},
			{"%RemoteCall%"}
		},
		["Spam"] = {
			{"-- Stop with Build > Undo Spam"},
			{"getgenv()._WVS_SPAM = true"},
			{"while getgenv()._WVS_SPAM do"},
			{"%RemoteCall%", 2},
			{"task.wait(0.1)", 2},
			{"end"}
		},
		["UndoSpam"] = {
			{"-- Stops Wyvern Spy spam loops"},
			{"getgenv()._WVS_SPAM = false"}
		},
		["Repeat"] = {
			{"for Index = 1, 10 do"},
			{"%RemoteCall%", 2},
			{"task.wait(0.05)", 2},
			{"end"}
		},
		["Block"] = {
			["__index"] = {
				{"local Old; Old = hookfunction(%Signal%, function(self, ...)"},
				{"if self == %Remote% then", 2},
				{"return", 3},
				{"end", 2},
				{"return Old(self, ...)", 2},
				{"end)"}
			},
			["__namecall"] = {
				{"local Old; Old = hookmetamethod(game, \"__namecall\", function(self, ...)"},
				{"local Method = getnamecallmethod()", 2},
				{"if self == %Remote% and Method == \"%Method%\" then", 2},
				{"return", 3},
				{"end", 2},
				{"return Old(self, ...)", 2},
				{"end)"}
			},
			["Connect"] = {
				{"for _, Connection in getconnections(%Signal%) do"},
				{"Connection:Disable()", 2},
				{"end"}
			}
		}
	}
}

local Config
local Hook
local ParserModule
local Flags
local ThisScript = script

local function Merge(Base: table, New: table?)
	if not New then return end
	for Key, Value in next, New do
		Base[Key] = Value
	end
end

function Generation:Init(Data: table)
    local Modules = Data.Modules
	local Configuration = Modules.Configuration

	
	Config = Modules.Config
	Hook = Modules.Hook
	Flags = Modules.Flags
	
	
	local ParserUrl = Configuration.ParserUrl
	self:LoadParser(ParserUrl)
end

function Generation:MakePrintable(String: string): string
	local Formatter = ParserModule.Modules.Formatter
	return Formatter:MakePrintable(String)
end

function Generation:TimeStampFile(FilePath: string): string
	local TimeStamp = os.date("%Y-%m-%d_%H-%M-%S")
	local Formatted = FilePath:format(TimeStamp)
	return Formatted
end

function Generation:WriteDump(Content: string): string
	local DumpBaseName = self.DumpBaseName
	local FilePath = self:TimeStampFile(DumpBaseName)

	
	writefile(FilePath, Content)

	return FilePath
end

function Generation:LoadParser(ModuleUrl: string)
	local function Fallback(Reason: string?)
		if Reason then
			warn("[Wyvern Spy] Parser load error:", Reason)
		end
		warn("[Wyvern Spy] Failed to load parser from:", ModuleUrl)
		warn("[Wyvern Spy] Script generation formatting may be limited.")
		ParserModule = {
			Modules = {
				Formatter = {
					MakePrintable = function(_, s) return tostring(s) end,
					MakeReplacements = function() return {} end,
					new = function()
						return {
							MakePrintable = function(_, s) return tostring(s) end,
							MakeReplacements = function() return {} end,
							Format = function(_, v) return tostring(v) end,
						}
					end,
				},
				Parser = {
					new = function()
						return {
							ParseTableIntoString = function() return "{}", 0, true end,
							MakePathString = function() return "nil", 0 end,
							MakeVariableCode = function() return "" end,
						}
					end,
				},
				Variables = {
					new = function() return {} end,
				},
			},
			New = function(self)
				return {
					Parser = self.Modules.Parser.new(),
					Formatter = self.Modules.Formatter.new(),
					Variables = self.Modules.Variables.new(),
				}
			end,
		}
	end

	if not ModuleUrl or #ModuleUrl == 0 then
		Fallback("ParserUrl is empty")
		return
	end

	
	local FetchOk, Source = pcall(function()
		return game:HttpGet(ModuleUrl)
	end)
	if not FetchOk or typeof(Source) ~= "string" or #Source < 100 then
		
		local Alt = ModuleUrl:gsub("/refs/heads/main/", "/main/")
		if Alt ~= ModuleUrl then
			FetchOk, Source = pcall(function()
				return game:HttpGet(Alt)
			end)
		end
	end
	if not FetchOk or typeof(Source) ~= "string" or #Source < 100 then
		Fallback(`HttpGet failed or empty body ({typeof(Source)})`)
		return
	end

	
	local Chunk, CompileErr = loadstring(Source, "Parser")
	if not Chunk then
		Fallback(`compile error: {CompileErr}`)
		return
	end

	
	local RunOk, Result = pcall(Chunk)
	if not RunOk then
		Fallback(`runtime error: {Result}`)
		return
	end
	if not Result or typeof(Result) ~= "table" or not Result.New then
		Fallback("parser did not return a valid module table")
		return
	end

	ParserModule = Result
	print("[Wyvern Spy] Parser loaded OK")
end

function Generation:MakeValueSwapsTable(): table
	local Formatter = ParserModule.Modules.Formatter
	return Formatter:MakeReplacements()
end

function Generation:SetSwapsCallback(Callback: (Interface: table) -> ())
	self.SwapsCallback = Callback
end

function Generation:GetBase(Module): (string, boolean)
	local NoComments = Flags:GetFlagValue("NoComments")
	local Header = self.Header

	local Code = NoComments and "" or Header

	
	local Variables = Module.Parser:MakeVariableCode({
		"Services", "Remote", "Variables"
	}, NoComments)

	local NoVariables = Variables == ""
	Code ..= Variables

	return Code, NoVariables
end

function Generation:GetSwaps()
	local Func = self.SwapsCallback
	local Swaps = {}

	local Interface = {}
	function Interface:AddSwap(Object: Instance, Data: table)
		if not Object then return end
		Swaps[Object] = Data
	end

	
	Func(Interface)

	return Swaps
end

function Generation:PickVariableName(): string
	local Names = Config.VariableNames
	return Names[math.random(1, #Names)]
end

function Generation:NewParser(Extra: table?)
	local VariableName = self:PickVariableName()
	local Swaps = self:GetSwaps()

	local Configuration = {
		VariableBase = VariableName,
		Swaps = Swaps,
		IndexFunc = function(...)
			return Hook:Index(...)
		end,
	}

	
	Merge(Configuration, Extra)

	
	return ParserModule:New(Configuration)
end

function Generation:Indent(IndentString: string, Line: string)
	return `{IndentString}{Line}`
end

type CallInfo = {
	Arguments: table,
	Indent: number,
	RemoteVariable: string,
	Module: table
}
function Generation:CallRemoteScript(Data, Info: CallInfo): string
	local IsReceive = Data.IsReceive
	local Method = Data.Method
	local Args = Data.Args

	local RemoteVariable = Info.RemoteVariable
	local Indent = Info.Indent or 0
	local Module = Info.Module

	local Variables = Module.Variables
	local Parser = Module.Parser
	local NoVariables = Data.NoVariables

	local IndentString = self:MakeIndent(Indent)

	
	local ParsedArgs, ItemsCount, IsArray = Parser:ParseTableIntoString({
		NoBrackets = true,
		NoVariables = NoVariables,
		Table = Args,
		Indent = Indent
	})

	
	if not IsArray or NoVariables then
		ParsedArgs = Variables:MakeVariable({
			Value = ("{%s}"):format(ParsedArgs),
			Comment = not IsArray and "Arguments aren't ordered" or nil,
			Name = "RemoteArgs",
			Class = "Remote"
		})
	end

	
	if ItemsCount > 0 and not IsArray then
		ParsedArgs = `unpack({ParsedArgs}, 1, table.maxn({ParsedArgs}))`
	end

	
	if IsReceive then
		local Second = ""
		if ItemsCount > 0 then
			Second = ", " .. tostring(ParsedArgs)
		end
		local Signal = tostring(RemoteVariable) .. "." .. tostring(Method)
		return tostring(IndentString) .. "firesignal(" .. Signal .. Second .. ")"
	end

	return tostring(RemoteVariable) .. ":" .. tostring(Method) .. "(" .. tostring(ParsedArgs) .. ")"
end

function Generation:ApplyVariables(String: string, Variables: table, ...): string
	for Variable, Value in Variables do
		if typeof(Value) == "function" then
			Value = Value(...)
		end
		-- Lua patterns: %% matches literal %
		local pattern = "%%" .. tostring(Variable) .. "%%"
		local replacement = tostring(Value)
		String = String:gsub(pattern, function()
			return replacement
		end)
	end
	return String
end


function Generation:MakeIndent(Indent: number)
	return string.rep("	", Indent)
end

type ScriptData = {
	Variables: table,
	MetaMethod: string
}
function Generation:MakeCallCode(ScriptType: string, Data: ScriptData): string
	local ScriptTemplates = self.ScriptTemplates
	local Template = ScriptTemplates[ScriptType]

	assert(Template, `{ScriptType} is not a valid script type!`)

	local Variables = Data.Variables
	local MetaMethod = Data.MetaMethod
	local MetaMethods = {"__index", "__namecall", "Connect"}

	local function Compile(Template: table): string
		local Out = ""

		for Key, Value in next, Template do
			
			local IsMetaTypeOnly = table.find(MetaMethods, Key)
			if IsMetaTypeOnly then
				if Key == MetaMethod then
					local Line = Compile(Value)
					Out ..= Line
				end
				continue
			end

			
			local Content, Indent = Value[1], Value[2] or 0
			Indent = math.clamp(Indent-1, 0, 9999)

			
			local Line = self:ApplyVariables(Content, Variables, Indent)
			local IndentString = self:MakeIndent(Indent)

			
			Out ..= `{IndentString}{Line}\n`
		end

		return Out
	end
	
	return Compile(Template)
end

function Generation:RemoteScript(Module, Data: RemoteData, ScriptType: string): string
	
	local Remote = Data.Remote
	local Args = Data.Args
	local Method = Data.Method
	local MetaMethod = Data.MetaMethod

	
	local ClassName = Hook:Index(Remote, "ClassName")
	local IsNilParent = Hook:Index(Remote, "Parent") == nil
	
	local Variables = Module.Variables
	local Formatter = Module.Formatter
	
	
	Variables:PrerenderVariables(Args, {"Instance"})

	
	local RemoteVariable = Variables:MakeVariable({
		Value = Formatter:Format(Remote, {
			NoVariables = true
		}),
		Comment = `{ClassName} {IsNilParent and "| Remote parent is nil" or ""}`,
		Name = Formatter:MakeName(Remote),
		Lookup = Remote,
		Class = "Remote"
	})

	
	local CallCode = self:MakeCallCode(ScriptType, {
		Variables = {
			["RemoteCall"] = function(Indent: number)
				return self:CallRemoteScript(Data, {
					RemoteVariable = RemoteVariable,
					Indent = Indent,
					Module = Module
				})
			end,
			["Remote"] = RemoteVariable,
			["Method"] = Method,
			["Signal"] = `{RemoteVariable}.{Method}`
		},
		MetaMethod = MetaMethod
	})
	
	
	local Code = self:GetBase(Module)
	return `{Code}\n{CallCode}`
end

function Generation:ConnectionsTable(Signal: RBXScriptSignal): table
	local Connections = getconnections(Signal)
	local DataArray = {}

	for _, Connection in next, Connections do
		local Function = Connection.Function
		local Script = rawget(getfenv(Function), "script")

		
		if Script == ThisScript then continue end

		
		local Data = {
			Function = Function,
			State = Connection.State,
			Script = Script
		}

		table.insert(DataArray, Data)
	end

	return DataArray
end

function Generation:TableScript(Module, Table: table): string
	
	Module.Variables:PrerenderVariables(Table, {"Instance"})

	
	local ParsedTable = Module.Parser:ParseTableIntoString({
		Table = Table
	})

	
	local Code, NoVariables = self:GetBase(Module)
	local Seperator = NoVariables and "" or "\n"
	Code ..= `{Seperator}return {ParsedTable}`

	return Code
end

function Generation:MakeTypesTable(Table: table): table
	local Types = {}

	for Key, Value in next, Table do
		local Type = typeof(Value)
		if Type == "table" then
			Type = self:MakeTypesTable(Value)
		end

		Types[Key] = Type
	end

	return Types
end

function Generation:ConnectionInfo(Remote: Instance, ClassData: table): table?
	local ReceiveMethods = ClassData.Receive
	if not ReceiveMethods then return end

	local Connections = {}
	for _, Method: string in next, ReceiveMethods do
		pcall(function() 
			local Signal = Hook:Index(Remote, Method)
			Connections[Method] = self:ConnectionsTable(Signal)
		end)
	end

	return Connections
end

function Generation:AdvancedInfo(Module, Data: table): string
	
	local Function = Data.CallingFunction
	local ClassData = Data.ClassData
	local Remote = Data.Remote
	local Args = Data.Args
	
	
	local FunctionInfo = {
		["Caller"] = {
			["SourceScript"] = Data.SourceScript,
			["CallingScript"] = Data.CallingScript,
			["CallingFunction"] = Function
		},
		["Remote"] = {
			["Remote"] = Remote,
			["RemoteID"] = Data.Id,
			["Method"] = Data.Method,
			["Connections"] = self:ConnectionInfo(Remote, ClassData)
		},
		["Arguments"] = {
			["Length"] = #Args,
			["Types"] = self:MakeTypesTable(Args),
		},
		["MetaMethod"] = Data.MetaMethod,
		["IsActor"] = Data.IsActor,
	}

	
	if Function and islclosure(Function) then
		FunctionInfo["UpValues"] = debug.getupvalues(Function)
		FunctionInfo["Constants"] = debug.getconstants(Function)
	end

	
	return self:TableScript(Module, FunctionInfo)
end

function Generation:DumpLogs(Logs: table): string
	local BaseData
	local Parsed = {
		Remote = nil,
		Calls = {}
	}

	
	local Module = Generation:NewParser()

	for _, Data in Logs do
		local Calls = Parsed.Calls
		local Table = {
			Args = Data.Args,
			Timestamp = Data.Timestamp,
			ReturnValues = Data.ReturnValues,
			Method = Data.Method,
			MetaMethod = Data.MetaMethod,
			CallingScript = Data.CallingScript,
		}

		
		table.insert(Calls, Table)

		
		if not BaseData then
			BaseData = Data
		end
	end

	
	Parsed.Remote = BaseData.Remote

	
	local Output = self:TableScript(Module, Parsed)
	local FilePath = self:WriteDump(Output)
	
	return FilePath
end

return Generation
