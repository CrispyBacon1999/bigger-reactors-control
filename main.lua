Reactor = {
    name = "",
    id = {},
    side = "",
    type = "",
    controlRodPID = {}
}

function Reactor:new(o, name)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = peripheral.wrap(name)
    self.name = "Reactor " .. (turbineCount + 1)
    self.controlRodPID = PIDController:new(nil, .5, 0, 0)
    reactorCount = reactorCount + 1
    return o
end

function Reactor:active()
    return self.id.active()
end

function Reactor:controlRodLevel()
    return self.id.getControlRod(0).level()
end

function Reactor:controlRodCount()
    return self.id.getNumberOfControlRods()
end

function Reactor:fuel()
    return self.id.fuelTank().fuel()
end

function Reactor:maxFuel()
    return self.id.fuelTank().capacity()
end

function Reactor:fuelPercentage()
    return Math.floor(self:fuel() / self:maxFuel() * 100)
end

function Reactor:setControlRodLevels(level)
    return self.id.setAllControlRodLevels(level)
end

function Reactor:steamExported()
    return self.id.coolantTank().transitionedLastTick()
end

function Reactor:steamGenerated()
    return self.id.coolantTank().maxTransitionedLastTick()
end

Turbine = {
    name = "",
    id = {},
    side = "",
    type = "",
    steamInputPID = {}
}

turbineCount = 0

function Turbine:new(o, name)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.name = "Turbine " .. (turbineCount + 1)
    self.side = name
    self.id = peripheral.wrap(name)
    self.steamInputPID = PIDController:new(nil, .5, 0, 0)
    self.steamInputPID:setSetpoint(targetTurbineRPM)
    turbineCount = turbineCount + 1
    return o
end

function Turbine:active()
    return self.id.active()
end

function Turbine:battery()
    return self.id.battery().stored()
end

function Turbine:maxBattery()
    return self.id.battery().capacity()
end

function Turbine:batteryProducedLastTick()
    return self.id.battery().producedLastTick()
end

function Turbine:batteryPercentage()
    return Math.floor(self:battery() / self:maxBattery() * 100)
end

function Turbine:rpm()
    return self.id.rotor().RPM()
end

function Turbine:efficiency()
    return self.id.rotor().efficiencyLastTick()
end

function Turbine:flowRate()
    return self.id.fluidTank().nominalFlowRate()
end

function Turbine:setFlowRate(rate)
    return self.id.fluidTank().setNominalFlowRate(rate)
end

PIDController = {
    kP = 1,
    kI = 0,
    kD = 0,
    setpoint = 0,
    previousError = 0,
    integral = 0
}

function PIDController:new(o, kP, kI, kD)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.kP = kP
    self.kI = kI
    self.kD = kD
    self.previousError = 0
    self.setpoint = 0
    self.integral = 0
    return o
end

function PIDController:setSetpoint(setpoint)
    self.setpoint = setpoint
end

function PIDController:calculate(currentValue)
    error = self.setpoint - currentValue
    self.integral = self.integral + (error)
    derivative = (error - self.previousError)
    self.previousError = error
    return self.kP * error + self.kI * self.integral + self.kD * derivative
end

reactorCount = 0
reactors = {}
turbineCount = 0
turbines = {}

-- Config

targetPowerStorage = 70
targetTurbineRPM = 1800

-- Communication variables
targetSteam = 0
controlRodOutput = 0

-- Discover devices
for i, v in pairs(peripheral.getNames()) do
    type = peripheral.getType(v)
    if type == "BiggerReactors_Reactor" then
        local reactor = Reactor:new(nil, v)
        reactors[reactorCount] = reactor
    end
    if type == "BiggerReactors_Turbine" then
        local turbine = Turbine:new(nil, v)
        turbines[turbineCount] = turbine
    end
end

for i = 1, turbineCount, 1 do
    print(turbines[i])
end

local function reactorControl()
    for i = 1, reactorCount, 1 do
        local reactor = reactors[i]
        reactor.controlRodPID:setSetpoint(targetSteam)
        controlRodOutput = 100 - reactor.controlRodPID:calculate(reactor:steamGenerated())
        reactor:setControlRodLevels(reactor:controlRodLevel() + controlRodOutput)
    end
end

local function turbineControl()
    targetSteam = 0
    for i = 1, turbineCount, 1 do
        local turbine = turbines[i]
        local rpm = turbine:rpm()
        local steamLevel = turbine.steamInputPID:calculate(rpm)
        local totalSteam = turbine:flowRate() + steamLevel
        targetSteam = targetSteam + totalSteam
        turbine:setFlowRate(totalSteam)
    end
end

local function log()
    print("ControlRod: " .. controlRodOutput .. " - Steam: " .. targetSteam)
end

print("Starting reactor control with " .. turbineCount .. " turbines and " .. reactorCount .. " reactors...")
while true do
    os.sleep(1)
    -- Run reactors
    reactorControl()
    -- Run turbines
    turbineControl()

    log()
end
