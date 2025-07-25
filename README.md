# Custom Lua Injector

A powerful OpenFunscripter extension that allows you to execute custom Lua code on selected actions without creating separate extensions. Perfect for quick one-time scripts and rapid prototyping.

## Features

- **Execute Custom Code**: Run single-line Lua scripts on selected actions
- **Code Library**: Save and load frequently used code snippets
- **Built-in Examples**: 4 practical examples to get you started
- **Comprehensive Help**: Detailed documentation and API references
- **Safe Execution**: Sandboxed environment for secure code execution
- **Keyboard Shortcuts**: Quick access via key bindings

## :hammer_and_wrench: Installation :hammer_and_wrench:

**Download from GitHub:**
1. Go to the GitHub repository: [GitHub - Hyeoyoms/CustomLuaInjector](https://github.com/Hyeoyoms/CustomLuaInjector)
2. Click the green "<> Code" button.
3. Select "Download ZIP".
4. Extract the `main.lua` file from the ZIP archive.
5. *(Alternatively, if you're familiar with Git, you can clone the repository.)*

**Place the .lua file in your OFS extensions folder:**
- The typical path is: `C:\Users\[YOUR_USERNAME]\AppData\Roaming\OFS\OFS3_data\extensions\`
- You can optionally create a subfolder within extensions (e.g., `CustomLuaInjector`) to keep things organized and place the `main.lua` file there.
- **Quick Tip to find the folder:** In OFS, go to Extensions > Extension directory. This will usually open a folder one level above where the extensions folder is located or directly into a script folder. Navigate to the extensions subfolder within OFS3_data.

**Load in OFS:**
- The extension should appear in your Extensions menu in OFS after placing it in the folder. You might need to restart OFS if it doesn't show up immediately.

## Usage

1. **Select Actions**: Drag to select actions in the OFS timeline
2. **Enter Code**: Type your Lua code in the input field
3. **Execute**: Click "Execute Code" to run your script

### Example Code

```lua
-- Increase all selected positions by 10%
for i, action in ipairs(selectedActions) do action.pos = math.min(100, action.pos * 1.1); end;

-- Remove actions with position ≤ 50
for i = #selectedActions, 1, -1 do if selectedActions[i].pos <= 50 then script:markForRemoval(getActionIndex(selectedActions[i])); end; end; script:removeMarked();

-- Add intermediate action when gap is large
for i, action in ipairs(selectedActions) do if action.pos == 90 and i < #selectedActions and (selectedActions[i + 1].at - action.at) >= 0.13 then table.insert(script.actions, Action.new(action.at + 0.06702, 80, false)); end; end;
```

## Available Functions & Variables

### OFS Official API
- `script`: Active funscript object (from `ofs.Script(ofs.ActiveIdx())`)
- `Action.new(at, pos, selected)`: Constructor for creating new actions
- `script:selectedIndices()`: Get array of selected action indices
- `script:markForRemoval(idx)`: Mark action for removal
- `script:removeMarked()`: Remove all marked actions
- `script:sort()`: Sort actions by time
- `script:commit()`: Apply changes to OFS
- Standard Lua libraries: `math`, `table`, `string`, `pairs`, `ipairs`, etc.

### Extension Helper Functions
- `selectedActions`: Pre-built array of currently selected actions
- `getActionIndex(targetAction)`: Find the index of a specific action
- `addAction(at, pos, selected)`: Convenient wrapper for creating and adding actions
- `print(...)`: Output text to extension result area (overrides standard print)

## API Reference

For complete API documentation, visit: https://openfunscripter.github.io/API/index.html

## Tips

- Use semicolons (`;`) to separate multiple statements
- `action.at` is time in seconds (0.1 = 100ms)
- `action.pos` is position value (0-100)
- Always validate array bounds with `i < #selectedActions`
- Use `math.min/max` for position clamping

## Contributing

Feel free to submit issues and pull requests to improve this extension.

## License

This project is open source and available under the MIT License.