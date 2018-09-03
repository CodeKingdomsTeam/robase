local Types = {}

function Types.Type( name, keyTypes )

	local type = {
		ClassName = 'Type',
		Name = name,
		Keys = keyTypes
	}
	return type

end

function Types.Class( name )

	return {
		ClassName = name
	}

end

return Types