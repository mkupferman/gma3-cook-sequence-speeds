-- PURPOSE:
-- Sets/overwrites the "Speed From X" recipe parameters in a GrandMA3
-- sequence to be a quotient of a Baseline Speed (BS) and the number
-- of fixtures in the selection. It then cooks the sequence (overwriting).
-- This is useful if you are creating phasers that should step along
-- to the beat of the music.
-- SAMPLE WORKFLOW:
-- 1. Create a phaser with N steps and set its "Measure" attribute to N.
-- 2. Create a sequence based on recipes, and reference the phaser.
-- 3. Label the receipe line "BS=s", where s is the Baseline Speed (dividend).
-- 4. Label the sequence and ensure it is set to a speedmaster.
-- 5. Build your selections and run this with the sequence *name* (not number)
--    (e.g. `call plugin 1 "Sequence Name"`)
-- NOTE:
-- In the absence of BlindEdit in MA3 at the time of writing,
-- this will clear out the programmer and select the sequence
-- in an effort to count the group items.
-- Be aware of your selection grid. If you have multi-instance
-- fixtures in your group, know that each box in the grid
-- counts toward the divisor.
local function usage()
    Echo("Usage: call plugin <N> \"Sequence Name\"")
end

local function main(handle, seqNameArg)
    if seqNameArg then
        local sequences = DataPool().Sequences
        local sequenceId = nil
        local recalcCount = 0
        -- find named sequence ID
        for s = 1, #sequences do
            local sequence = sequences[s]
            if sequence ~= nil then
                if sequence['Name'] and sequence['Name'] ~= nil then
                    if sequence['Name'] == seqNameArg then
                        sequenceId = s
                        break
                    end
                end
            end
        end
        if sequenceId == nil then
            Echo("Sequence not found: " .. seqNameArg)
        else
            local sequence = sequences[sequenceId]
            local cues = sequence:Children()
            for i, cue in ipairs(cues) do
                local parts = cue:Children()
                for j, part in ipairs(parts) do
                    local recipes = part:Children()
                    for k, recipe in ipairs(recipes) do
                        -- look for Baseline Speed ("BS=") receipe label
                        if recipe['Name']:find("^BS=") ~= nil then
                            recalcCount = recalcCount + 1
                            Echo("*** Seq '" .. sequence['Name'] .. "' Cue " .. i .. " Part " .. j .. " Recipe " .. k)
                            local baseSpeed = recipe['Name']:sub(4)
                            baseSpeed = baseSpeed + 0.0

                            local selection = recipe['SELECTION']
                            local groupIndex = selection['INDEX']
                            Cmd("preview on")
                            Cmd("clearall")
                            Cmd("group " .. groupIndex)
                            local numFixtures = SelectionCount() + 0.0
                            Cmd("clearall")
                            Cmd("preview off")
                            Echo("Using " .. numFixtures .. " fixtures")

                            local currentSpeed = recipe['SPEEDFROMX']
                            local newSpeed = baseSpeed / numFixtures

                            -- GMA3 v2 sets in BPM. GMA3 v1 set in BPH[our]
                            local versionMajor = tonumber(Version():sub(1, 1))
                            if versionMajor < 2 then
                                recipe['SPEEDFROMX'] = newSpeed / 60.0
                            else
                                recipe['SPEEDFROMX'] = newSpeed
                            end

                            Echo("Setting speed to " .. newSpeed .. " BPM from baseline " .. baseSpeed)
                        end
                    end
                end
            end
            Echo(recalcCount .. " recipe timings recalculated. Cooking...")
            Cmd("cook seq \"" .. seqNameArg .. "\" /o")
        end
    else
        usage()
    end
end

return main
