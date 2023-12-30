return {
	IsColor3 = function(value)
		return pcall(function() local r, g, b = value.r, value,g, value.b end)
	end;
	IsCFrame = function(value)
		return pcall(function() local c = value:components() end)
	end;
	IsVector3 = function(value)
		local test1 = pcall(function() local x, y, z = value.X, value.Y, value.Z end)
		local test2 = pcall(function() local c = value:components() end)
		return (test1 and not test2)
	end;
	IsUDim2 = function(value)
		return pcall(function() local xs, xo, ys, yo = value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset end)
	end
}