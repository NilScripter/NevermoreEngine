--- Base class for ragdolls, meant to be used with binders
-- @classmod Ragdoll

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local Workspace = game:GetService("Workspace")

local RagdollBase = require("RagdollBase")
local RagdollUtils = require("RagdollUtils")

local Ragdoll = setmetatable({}, RagdollBase)
Ragdoll.ClassName = "Ragdoll"
Ragdoll.__index = Ragdoll

function Ragdoll.new(humanoid)
	local self = setmetatable(RagdollBase.new(humanoid), Ragdoll)

	self._obj.BreakJointsOnDeath = false
	self._obj:ChangeState(Enum.HumanoidStateType.Physics)
	self:StopAnimations()

	self._maid:GiveTask(function()
		self._obj:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	self:_setupRootPart()

	for _, balljoint in pairs(RagdollUtils.createBallJoints(self._obj)) do
		self._maid:GiveTask(balljoint)
	end

	for _, noCollision in pairs(RagdollUtils.createNoCollision(self._obj)) do
		self._maid:GiveTask(noCollision)
	end

	for _, motor in pairs(RagdollUtils.getMotors(self._obj)) do
		local originalParent = motor.Parent
		motor.Parent = nil

		self._maid:GiveTask(function()
			if originalParent:IsDescendantOf(Workspace) then
				motor.Parent = originalParent
			else
				motor:Destroy()
			end
		end)
	end

	-- After joints have been removed
	self:_setupHead()

	return self
end

function Ragdoll:_setupHead()
	local model = self._obj.Parent
	if not model then
		return
	end

	local head = model:FindFirstChild("Head")
	if not head then
		return
	end

	local originalSize = head.Size
	head.Size = Vector3.new(1, 1, 1)

	self._maid:GiveTask(function()
		head.Size = originalSize
	end)
end

function Ragdoll:_setupRootPart()
	local rootPart = self._obj.RootPart
	if not rootPart then
		return
	end

	rootPart.Massless = true
	rootPart.CanCollide = false

	self._maid:GiveTask(function()
		rootPart.Massless = false
		rootPart.CanCollide = true
	end)
end

return Ragdoll