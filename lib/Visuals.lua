local Visuals = {}

function Visuals.Show( object ) --: Instance => void

    object.CanCollide = true
	object.Transparency = 0

end

function Visuals.Hide( object ) --: Instance => void

    object.CanCollide = false
	object.Transparency = 1

end

return Visuals