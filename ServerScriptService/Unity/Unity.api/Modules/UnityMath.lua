local output = {}

function output:DeconstructCFrame(CFrame)
	--Returns a CFrame's components into separate vectors nicely
	local px,py,pz,xx,yx,zx,xy,yy,zy,xz,yz,zz = CFrame:components()
	local Position = Vector3.new(px,py,pz)
	local Right = Vector3.new(xx,xy,xz)
	local Top = Vector3.new(yx,yy,yz)
	local Back = Vector3.new(zx,zy,zz)
	return Position,Right,Top,Back
end

return output