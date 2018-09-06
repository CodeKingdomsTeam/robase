local Logger = {}

Logger.LOG_LEVEL = {
	AUTO = "Auto",
	TRACE = "Trace",
	DEBUG = "Debug",
	LOG = "Log",
	WARN = "Warn",
	ERROR = "Error"
}

function Logger.Raise(level, ...) --: string, ...any => void
	print("[", level, "] ", ...)
end

function Logger.Trace(...) --: ...any => void
	Logger.Raise("Trace", ...)
end
function Logger.Debug(...) --: ...any => void
	Logger.Raise("Debug", ...)
end
function Logger.Log(...) --: ...any => void
	Logger.Raise("Log", ...)
end
function Logger.Warn(...) --: ...any => void
	Logger.Raise("Warn", ...)
end
function Logger.Error(...) --: ...any => void
	Logger.Raise("Error", ...)
end

return Logger
