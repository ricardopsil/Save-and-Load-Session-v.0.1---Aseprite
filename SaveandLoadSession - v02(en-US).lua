local path = os.getenv('APPDATA') .. "/Aseprite/scripts/"
local sessionDir = path .. "sessions/"
local sessions = {}

-- Function to create directory if it does not exist
function ensureDirectoryExists(dir)
  if not app.fs.isDirectory(dir) then
    app.fs.makeDirectory(dir)
  end
  return app.fs.isDirectory(dir)
end

-- Check if the sessions folder exists
if not ensureDirectoryExists(sessionDir) then
  app.alert("The sessions folder could not be created! Check permissions.")
  return
end

-- Function to list sessions using Aseprite's native API
function listSessions()
  sessions = {}
  local files = app.fs.listFiles(sessionDir)
  
  for _, file in ipairs(files) do
    if file:find("%.txt$") then
      sessions[#sessions + 1] = file:gsub("%.txt$", "")
    end
  end
  
  -- Sort sessions alphabetically
  table.sort(sessions)
end

-- Session save function
function saveSession(sessionName)
  if not sessionName or sessionName == "" then
    app.alert("Error: Session name cannot be empty!")
    return false
  end
  
  local sessionFile = sessionDir .. sessionName .. ".txt"
  local file = io.open(sessionFile, "w+")
  if not file then
    app.alert("Error saving session. Check permissions.")
    return false
  end
  
  local count = 0
  for _, sprite in ipairs(app.sprites) do
    if sprite.filename and sprite.filename ~= "" then
      file:write(sprite.filename .. "\n")
      count = count + 1
    end
  end
  file:close()
  
  if count == 0 then
    app.alert("Warning: No files were saved (sprites without file names).")
  else
    app.alert("Session saved: " .. sessionName .. " (" .. count .. " files)")
  end
  return true
end

function loadSession(sessionName)
  local sessionFile = sessionDir .. sessionName .. ".txt"
  local file = io.open(sessionFile, "r")
  if not file then
    app.alert("Error: Session '" .. sessionName .. "' not found!")
    return
  end
  
  local loadedFiles = 0
  local errors = {}
  
  for line in file:lines() do
    line = line:match("^%s*(.-)%s*$")
    if line and line ~= "" then
      if app.fs.isFile(line) then
        app.open(line)
        loadedFiles = loadedFiles + 1
      else
        table.insert(errors, line)
      end
    end
  end
  file:close()
  
  if #errors > 0 then
    app.alert("Session loaded with warnings:\n" .. 
              loadedFiles .. " uploaded files\n" .. 
              #errors .. " files not found")
  else
    app.alert("Session loaded: " .. loadedFiles .. " files")
  end
end

function deleteSession(sessionName)
  local sessionFile = sessionDir .. sessionName .. ".txt"
  if app.fs.isFile(sessionFile) then
    os.remove(sessionFile)
    return true
  end
  return false
end

listSessions()

local dlg = Dialog("Session Manager")

dlg:button{
  id = "save",
  text = "Save Session",
  onclick = function()
    local inputDlg = Dialog("Save Session")
    inputDlg:entry{
      id = "name", 
      label = "Session Name:",
      text = ""
    }
    inputDlg:button{
      id = "save_confirm",
      text = "Save",
      onclick = function()
        local name = inputDlg.data.name
        if saveSession(name) then
          listSessions()
          inputDlg:close()
        end
      end
    }
    inputDlg:button{
      id = "cancel",
      text = "Cancel",
      onclick = function()
        inputDlg:close()
      end
    }
    inputDlg:show{wait = true}
  end
}

dlg:button{
  id = "load",
  text = "Load Session",
  onclick = function()
    if #sessions == 0 then
      app.alert("No sessions found!")
      return
    end
    
    local loadDlg = Dialog("Load Session")
    
    -- Combobox 
    loadDlg:combobox{
      id = "session_list",
      label = "Session:",
      options = sessions,
      option = sessions[1] or ""
    }
    
    loadDlg:button{
      id = "load_confirm",
      text = "Load",
      onclick = function()
        local selectedSession = loadDlg.data.session_list
        if selectedSession and selectedSession ~= "" then
          loadSession(selectedSession)
          loadDlg:close()
        end
      end
    }
    
    loadDlg:button{
      id = "delete",
      text = "Delete",
      onclick = function()
        local selectedSession = loadDlg.data.session_list
        if selectedSession and selectedSession ~= "" then
          local confirm = app.alert{
            title = "Confirm Deletion",
            text = "Are you sure you want to delete the session? '" .. selectedSession .. "'?",
            buttons = {"Yes", "No"}
          }
          if confirm == 1 then
            if deleteSession(selectedSession) then
              app.alert("Session deleted: " .. selectedSession)
              listSessions()
              -- Atualiza o combobox e permanece na tela
              loadDlg:modify{id = "session_list", options = sessions, option = sessions[1] or ""}
            else
              app.alert("Error deleting session!")
            end
          end
        end
      end
    }
    
    loadDlg:button{
      id = "cancel_load",
      text = "Cancel",
      onclick = function()
        loadDlg:close()
      end
    }
    
    loadDlg:show{wait = true}
  end
}

dlg:button{
  id = "close",
  text = "Close",
  onclick = function() 
    dlg:close() 
  end
}

dlg:show{wait = false}