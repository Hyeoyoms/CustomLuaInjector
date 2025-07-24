--[[
    Custom Lua Injector Extension for OpenFunscripter
    
    Execute custom Lua code on selected actions without creating separate extensions.
    Ideal for quick one-time scripts and rapid prototyping.
    
    Repository: https://github.com/OpenFunscripter/OFS
    Documentation: https://openfunscripter.github.io/API/index.html
--]]

local customCode = ""
local lastError = ""
local executionResult = ""
local showHelp = false
local showSaveLoad = false

local exampleCommands = {
    "for i, action in ipairs(selectedActions) do action.pos = math.min(100, action.pos * 1.1); end;",
    "for i = #selectedActions, 1, -1 do if selectedActions[i].pos <= 50 then script:markForRemoval(getActionIndex(selectedActions[i])); end; end; script:removeMarked();",
    "for i, action in ipairs(selectedActions) do if action.pos == 90 and i < #selectedActions and (selectedActions[i + 1].at - action.at) >= 0.13 then table.insert(script.actions, Action.new(action.at + 0.06702, 80, false)); end; end;",
    "for i, action in ipairs(selectedActions) do action.at = action.at + 0.1; end;"
}
local selectedExampleIndex = 1

local savedCodes = {}
local savedCodeNames = {}
local selectedSavedIndex = 1
local saveCodeName = ""

function binding.executeCustomCode()
    executeCustomLuaCode()
end

function binding.clearCode()
    customCode = ""
    lastError = ""
    executionResult = ""
end

function init()
    print("Custom Lua Injector v1.0.0 initialized")
    loadSavedCodes()
end

function update(delta)
end

function gui()
    ofs.Text("Custom Lua Injector v1.0.0")
    ofs.Separator()
    
    showHelp = ofs.Checkbox("Show Documentation", showHelp)
    
    if showHelp then
        renderHelpSection()
    end
    
    renderCodeInputSection()
    renderSaveLoadSection()
    renderActionButtons()
    renderOutputSection()
end

function renderHelpSection()
    ofs.Separator()
    ofs.Text("IMPORTANT: Single-line code only!")
    ofs.Text("Use semicolons (;) to separate multiple statements on one line.")
    ofs.Text("")
    
    ofs.Text("Quick Start:")
    ofs.Text("1. Select actions in OFS timeline by dragging")
    ofs.Text("2. Enter Lua code in the input field below")
    ofs.Text("3. Click 'Execute Code' to run your script")
    ofs.Text("")
    
    ofs.Text("Available Variables:")
    ofs.Text("- selectedActions: Array of currently selected actions")
    ofs.Text("- script: Active funscript object")
    ofs.Text("- Action: Constructor for new actions")
    ofs.Text("- Helper functions: getActionIndex(), addAction(), print()")
    ofs.Text("")
    
    ofs.Text("Official API Documentation:")
    ofs.Text("https://openfunscripter.github.io/API/index.html")
    ofs.Text("")
    
    ofs.Text("Pro Tips:")
    ofs.Text("- action.at = time in seconds (0.1 = 100ms)")
    ofs.Text("- action.pos = position value (0-100)")
    ofs.Text("- Always validate array bounds: 'i < #selectedActions'")
    ofs.Text("- Use math.min/max for position clamping")
    ofs.Text("")
    
    ofs.Text("Built-in Examples:")
    selectedExampleIndex, _ = ofs.Combo("Select Example", selectedExampleIndex, {
        "Increase positions by 10%", 
        "Remove low positions (≤50)", 
        "Smart gap filling (90→80)", 
        "Time shift (+100ms)"
    })
    
    if ofs.Button("Load Example Code") then
        customCode = exampleCommands[selectedExampleIndex]
    end
    
    ofs.Text("")
    ofs.Text("Example Description:")
    local descriptions = {
        "Multiplies all selected action positions by 1.1 (10% increase)",
        "Removes actions with position values 50 or lower",
        "Adds pos=80 action 67ms after pos=90 when gap ≥130ms",
        "Shifts all selected actions 100ms later in timeline"
    }
    ofs.Text(descriptions[selectedExampleIndex])
    
    ofs.Separator()
end

function renderCodeInputSection()
    ofs.Text("Lua Code Input:")
    customCode, _ = ofs.Input("##customCode", customCode)
    
    ofs.SameLine()
    if ofs.Button("Clear") then
        customCode = ""
        lastError = ""
        executionResult = ""
    end
end

function renderSaveLoadSection()
    ofs.Separator()
    showSaveLoad = ofs.Checkbox("Code Library", showSaveLoad)
    
    if showSaveLoad then
        ofs.Text("Save Current Code:")
        saveCodeName, _ = ofs.Input("Snippet Name", saveCodeName)
        ofs.SameLine()
        if ofs.Button("Save") then
            saveCurrentCode()
        end
        
        if #savedCodeNames > 0 then
            ofs.Text("Load Saved Code:")
            selectedSavedIndex, _ = ofs.Combo("Saved Snippets", selectedSavedIndex, savedCodeNames)
            ofs.SameLine()
            if ofs.Button("Load") then
                loadSelectedCode()
            end
            ofs.SameLine()
            if ofs.Button("Delete") then
                deleteSelectedCode()
            end
        else
            ofs.Text("No saved code snippets yet")
        end
        ofs.Separator()
    end
end

function renderActionButtons()
    if ofs.Button("Execute Code") then
        executeCustomLuaCode()
    end
    
    ofs.SameLine()
    if ofs.Button("Inspect Selection") then
        showSelectedActionsInfo()
    end
end

function renderOutputSection()
    if executionResult ~= "" then
        ofs.Separator()
        ofs.Text("Result:")
        ofs.Text(executionResult)
    end
    
    if lastError ~= "" then
        ofs.Separator()
        ofs.Text("Error:")
        ofs.Text(lastError)
    end
end

function showSelectedActionsInfo()
    local script = ofs.Script(ofs.ActiveIdx())
    if not script then
        executionResult = "No active script loaded."
        return
    end
    
    if not script:hasSelection() then
        executionResult = "No actions currently selected."
        return
    end
    
    local selectedIndices = script:selectedIndices()
    local info = string.format("Selection Analysis (%d actions):\n", #selectedIndices)
    
    local displayLimit = math.min(10, #selectedIndices)
    for i = 1, displayLimit do
        local idx = selectedIndices[i]
        local action = script.actions[idx]
        info = info .. string.format("  [%d] t=%.3fs, pos=%d\n", i, action.at, action.pos)
    end
    
    if #selectedIndices > displayLimit then
        info = info .. string.format("  ... and %d more actions\n", #selectedIndices - displayLimit)
    end
    
    executionResult = info
    lastError = ""
end

function executeCustomLuaCode()
    lastError = ""
    executionResult = ""
    
    if customCode == "" then
        lastError = "No code provided. Enter Lua code above."
        return
    end
    
    local script = ofs.Script(ofs.ActiveIdx())
    if not script then
        lastError = "No active script. Please load a funscript first."
        return
    end
    
    if not script:hasSelection() then
        lastError = "No actions selected. Select actions in timeline first."
        return
    end
    
    local selectedIndices = script:selectedIndices()
    local selectedActions = {}
    for i, idx in ipairs(selectedIndices) do
        selectedActions[i] = script.actions[idx]
    end
    
    local sandboxEnv = createSandboxEnvironment(selectedActions, script)
    
    local compiledFunction, compileError = load(customCode, "user_script", "t", sandboxEnv)
    if not compiledFunction then
        lastError = "Compilation failed: " .. tostring(compileError)
        return
    end
    
    local success, runtimeError = pcall(compiledFunction)
    if not success then
        lastError = "Runtime error: " .. tostring(runtimeError)
        return
    end
    
    script:sort()
    script:commit()
    
    if executionResult == "" then
        executionResult = string.format("Executed successfully on %d actions", #selectedActions)
    end
    
    print("Custom code execution completed")
end

function createSandboxEnvironment(selectedActions, script)
    return {
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        type = type,
        tostring = tostring,
        tonumber = tonumber,
        string = string,
        table = table,
        math = math,
        
        selectedActions = selectedActions,
        script = script,
        Action = Action,
        
        getActionIndex = function(targetAction)
            for i, action in ipairs(script.actions) do
                if action == targetAction then
                    return i
                end
            end
            return nil
        end,
        
        addAction = function(at, pos, selected)
            selected = selected or false
            local newAction = Action.new(at, pos, selected)
            table.insert(script.actions, newAction)
            return newAction
        end,
        
        print = function(...)
            local args = {...}
            local output = ""
            for i, v in ipairs(args) do
                output = output .. tostring(v)
                if i < #args then 
                    output = output .. "\t" 
                end
            end
            executionResult = executionResult .. output .. "\n"
        end
    }
end

function getSaveFilePath()
    return ofs.ExtensionDir() .. "/saved_codes.txt"
end

function loadSavedCodes()
    local filePath = getSaveFilePath()
    local file = io.open(filePath, "r")
    if not file then
        return
    end
    
    savedCodes = {}
    savedCodeNames = {}
    
    local currentName = nil
    for line in file:lines() do
        if line:sub(1, 6) == "NAME: " then
            currentName = line:sub(7)
        elseif line:sub(1, 6) == "CODE: " and currentName then
            local code = line:sub(7)
            table.insert(savedCodeNames, currentName)
            savedCodes[currentName] = code
            currentName = nil
        end
    end
    
    file:close()
    
    if #savedCodeNames > 0 then
        selectedSavedIndex = 1
    end
end

function saveCodesToFile()
    local filePath = getSaveFilePath()
    local file = io.open(filePath, "w")
    if not file then
        lastError = "Failed to write to storage file"
        return false
    end
    
    for _, name in ipairs(savedCodeNames) do
        file:write("NAME: " .. name .. "\n")
        file:write("CODE: " .. savedCodes[name] .. "\n")
    end
    
    file:close()
    return true
end

function saveCurrentCode()
    if saveCodeName == "" then
        lastError = "Please provide a name for the code snippet"
        return
    end
    
    if customCode == "" then
        lastError = "No code to save"
        return
    end
    
    local existingIndex = nil
    for i, name in ipairs(savedCodeNames) do
        if name == saveCodeName then
            existingIndex = i
            break
        end
    end
    
    if not existingIndex then
        table.insert(savedCodeNames, saveCodeName)
    end
    
    savedCodes[saveCodeName] = customCode
    
    if saveCodesToFile() then
        executionResult = "Saved as: " .. saveCodeName
        lastError = ""
        saveCodeName = ""
    end
end

function loadSelectedCode()
    if #savedCodeNames == 0 then
        lastError = "No saved code snippets available"
        return
    end
    
    local selectedName = savedCodeNames[selectedSavedIndex]
    if savedCodes[selectedName] then
        customCode = savedCodes[selectedName]
        executionResult = "Loaded: " .. selectedName
        lastError = ""
    else
        lastError = "Failed to load snippet: " .. selectedName
    end
end

function deleteSelectedCode()
    if #savedCodeNames == 0 then
        lastError = "No saved code snippets to delete"
        return
    end
    
    local selectedName = savedCodeNames[selectedSavedIndex]
    
    table.remove(savedCodeNames, selectedSavedIndex)
    savedCodes[selectedName] = nil
    
    if selectedSavedIndex > #savedCodeNames then
        selectedSavedIndex = math.max(1, #savedCodeNames)
    end
    
    if saveCodesToFile() then
        executionResult = "Deleted: " .. selectedName
        lastError = ""
    end
end

function scriptChange(scriptIdx)
end