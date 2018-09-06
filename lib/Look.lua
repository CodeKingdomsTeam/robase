local Look = {}

function Look.Show(object) --: Instance => void
	object.CanCollide = true
	object.Transparency = 0
end

function Look.Hide(object) --: Instance => void
	object.CanCollide = false
	object.Transparency = 1
end

return Look
