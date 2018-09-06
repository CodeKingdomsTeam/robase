--[[
    This Logger builds upon Roblox's base print system - messages are only actually displayed as
    long as the configured log level allows (for example, if it's setup to 'Warn', it will only
    print messages of 'Warn' or above).
]]

-- Create return table
local Logger = {}

--[[
    Shouldn't really be used externally, as it bypasses the entire display system. Prints out the
    specified message to console.
]]
function Logger.Raise( level, ... ) --: string, ...any => void

    print("[", level, "] ", ...)
    
end

--[[
    Trace is for even lower level information than debugging. It breaks down code progress, and variable
    states even further. Should only be used in specific circumstances.
]]
function Logger.Trace( ... ) --: ...any => void
    Logger.Raise("Trace", ...)
end

--[[
    When trying to resolve a bug, debug level type is best. For example, notification of event firing is great debug
]]
function Logger.Debug( ... ) --: ...any => void
    Logger.Raise("Debug", ...)
end

--[[
    Used for generic, run-of-the-mill updates
]]
function Logger.Log( ... ) --: ...any => void
    Logger.Raise("Log", ...)
end

--[[
    Should be used where something is not operating optimally, but still executes it's base function
]]
function Logger.Warn( ... ) --: ...any => void
    Logger.Raise("Warn", ...)
end

--[[
    Should be used where something is not executing it's base function
]]
function Logger.Error( ... ) --: ...any => void
    Logger.Raise("Error", ...)
end

return Logger