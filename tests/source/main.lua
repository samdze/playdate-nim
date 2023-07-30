function playdate.update()
    -- Blank on purpose. The main work here is being done in the Nim layer.
    -- The lua layer only exists so that we can call playdate.simulator.exit().
    playdate.simulator.exit()
end