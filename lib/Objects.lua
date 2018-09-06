local Objects = {}

Objects.CLASS_TYPE = {
    EXPLOSION = "Explosion"
}

--- Make a new Roblox Instance and optionally provide it with a position,
--- parent and name
function Objects.Create( type, properties ) 

    local object = Instance.new( type )
    
    Objects.Modify(object, properties)

    return object

end

function Objects.Modify( object, properties)

    local parent = nil
    if(properties.Parent)then
        parent = properties.Parent
        properties.Parent = nil
    end 

    for property, value in pairs(properties)do
        local ok = pcall(function()
            object[property] = value
        end)

        if not ok then
            if(object:IsA("Model"))then
                if(property == "Position")then
                    object:SetPrimaryPartCFrame(value)
                end 
            end
        end

    end

    if(parent)then
        object.Parent = parent
    end 
end 

function Objects.Clone( object, properties ) --: <T extends Instance>(T, Vector3?, Object?) => T

    local clone = object:Clone()
    Objects.Modify(clone, properties)

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