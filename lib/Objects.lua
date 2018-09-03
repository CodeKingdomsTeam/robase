local Objects = {}

Objects.CLASS_TYPE = {
    EXPLOSION = "Explosion"
}

--- Make a new Roblox Instance and optionally provide it with a position,
--- parent and name
function Objects.Create( type, position, parent, name ) --: <T extends CLASS_TYPE>(T, position?, parent?, name?) => Instance<T>

    local object = Instance.new( type )
    object.Name = name or type
    if ( position ) then
        object.Position = position
    end

    object.Parent = parent or game.Workspace

    return object

end

function Objects.Clone( object, position, parent ) --: <T extends Instance>(T, Vector3?, Object?) => T

    local clone = object:Clone()
    if ( position ) then
        clone.Position = position
    end
    clone.Parent = parent or game.Workspace

    return clone

end

--- Get the torso for a paticular character
function Objects.GetTorso( character ) --: Character => BasePart

    return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

end

Objects.FieldTable = {} --: <T>{[key: string]: Serializable}

--- Get the fields of an object
function Objects.Fields( object ) --: <T extends Instance>(T) => FieldTable<T>

	local fieldTable = {}
	local mt = {
	
        __index = function(_, key ) 
            local child = object:FindFirstChild( key )
            if ( not child ) then
                return nil
            end
            return child.Value
        
        end,
        __newindex = function(_, key, value )
            local child = object:FindFirstChild( key )
            if ( not child ) then

                local valueType = nil
                if ( type(value) == "string" ) then
                    valueType = "StringValue"
                elseif ( type(value) == "boolean" ) then
                    valueType = "BoolValue"
                elseif ( type(value) == "number" ) then
                    valueType = "NumberValue"
                else
                    valueType = "ObjectValue"
                end

                child = Instance.new(valueType)
                child.Name = key
                child.Parent = object

            end

            child.Value = value
            
        end
	}
    setmetatable(fieldTable, mt)
	return fieldTable

end


return Objects