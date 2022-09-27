Reactor = {
    name = "",
    id = {},
    side = "",
    type = ""
}

function Reactor:new(o, name)
    self.id = peripheral.wrap(name)
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
    type = ""
}

turbineCount = 0

function Turbine:new(o, name)
    self.name = "Turbine " .. (turbineCount + 1)
    turbineCount = turbineCount + 1
    self.side = name
    self.id = peripheral.wrap(name)
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

reactors = {}
turbines = {}

-- Discover devices
for i, v in pairs(peripheral.getNames()) do
    type = peripheral.getType(v)
    if type == "BiggerReactors_Reactor" then
        reactor = Reactor:new(nil, v)
        reactors[table.getn(reactors) + 1] = reactor
    end
    if type == "BiggerReactors_Turbine" then
        turbine = Turbine:new(nil, v)
        turbines[table.getn(turbines) + 1] = turbine
    end
end

for i, v in ipairs(turbines) do
    print(v.name)
end
