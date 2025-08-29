local path = os.getenv('APPDATA') .. "/Aseprite/scripts/"
local sessionDir = path .. "sessions/"
local sessions = {}

-- Função para criar diretório se não existir
function ensureDirectoryExists(dir)
  if not app.fs.isDirectory(dir) then
    app.fs.makeDirectory(dir)
  end
  return app.fs.isDirectory(dir)
end

-- Verifica se a pasta de sessões existe
if not ensureDirectoryExists(sessionDir) then
  app.alert("A pasta de sessões não pôde ser criada! Verifique permissões.")
  return
end

-- Função para listar sessões usando API nativa do Aseprite
function listSessions()
  sessions = {}
  local files = app.fs.listFiles(sessionDir)
  
  for _, file in ipairs(files) do
    if file:find("%.txt$") then
      sessions[#sessions + 1] = file:gsub("%.txt$", "")
    end
  end
  
  -- Ordena as sessões alfabeticamente
  table.sort(sessions)
end

-- Função para salvar sessão
function saveSession(sessionName)
  if not sessionName or sessionName == "" then
    app.alert("Erro: Nome da sessão não pode estar vazio!")
    return false
  end
  
  local sessionFile = sessionDir .. sessionName .. ".txt"
  local file = io.open(sessionFile, "w+")
  if not file then
    app.alert("Erro ao salvar a sessão. Verifique permissões.")
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
    app.alert("Aviso: Nenhum arquivo foi salvo (sprites sem nome de arquivo).")
  else
    app.alert("Sessão salva: " .. sessionName .. " (" .. count .. " arquivos)")
  end
  return true
end

-- Função para carregar sessão
function loadSession(sessionName)
  local sessionFile = sessionDir .. sessionName .. ".txt"
  local file = io.open(sessionFile, "r")
  if not file then
    app.alert("Erro: Sessão '" .. sessionName .. "' não encontrada!")
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
    app.alert("Sessão carregada com avisos:\n" .. 
              loadedFiles .. " arquivos carregados\n" .. 
              #errors .. " arquivos não encontrados")
  else
    app.alert("Sessão carregada: " .. loadedFiles .. " arquivos")
  end
end

-- Função para deletar sessão
function deleteSession(sessionName)
  local sessionFile = sessionDir .. sessionName .. ".txt"
  if app.fs.isFile(sessionFile) then
    os.remove(sessionFile)
    return true
  end
  return false
end

-- Carrega sessões apenas uma vez no início
listSessions()

-- Criação do diálogo principal
local dlg = Dialog("Gerenciador de Sessões")

dlg:button{
  id = "save",
  text = "Salvar Sessão",
  onclick = function()
    local inputDlg = Dialog("Salvar Sessão")
    inputDlg:entry{
      id = "name", 
      label = "Nome da Sessão:",
      text = ""
    }
    inputDlg:button{
      id = "save_confirm",
      text = "Salvar",
      onclick = function()
        local name = inputDlg.data.name
        if saveSession(name) then
          listSessions() -- Atualiza a lista apenas após salvar
          inputDlg:close()
        end
      end
    }
    inputDlg:button{
      id = "cancel",
      text = "Cancelar",
      onclick = function()
        inputDlg:close()
      end
    }
    inputDlg:show{wait = true}
  end
}

dlg:button{
  id = "load",
  text = "Carregar Sessão",
  onclick = function()
    if #sessions == 0 then
      app.alert("Nenhuma sessão encontrada!")
      return
    end
    
    local loadDlg = Dialog("Carregar Sessão")
    
    -- Usa combobox em vez de múltiplos botões para melhor performance
    loadDlg:combobox{
      id = "session_list",
      label = "Sessão:",
      options = sessions,
      option = sessions[1] or ""
    }
    
    loadDlg:button{
      id = "load_confirm",
      text = "Carregar",
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
      text = "Deletar",
      onclick = function()
        local selectedSession = loadDlg.data.session_list
        if selectedSession and selectedSession ~= "" then
          local confirm = app.alert{
            title = "Confirmar Exclusão",
            text = "Tem certeza que deseja deletar a sessão '" .. selectedSession .. "'?",
            buttons = {"Sim", "Não"}
          }
          if confirm == 1 then
            if deleteSession(selectedSession) then
              app.alert("Sessão deletada: " .. selectedSession)
              listSessions()
              -- Atualiza o combobox e permanece na tela
              loadDlg:modify{id = "session_list", options = sessions, option = sessions[1] or ""}
            else
              app.alert("Erro ao deletar a sessão!")
            end
          end
        end
      end
    }
    
    loadDlg:button{
      id = "cancel_load",
      text = "Cancelar",
      onclick = function()
        loadDlg:close()
      end
    }
    
    loadDlg:show{wait = true}
  end
}

dlg:button{
  id = "close",
  text = "Fechar",
  onclick = function() 
    dlg:close() 
  end
}

dlg:show{wait = false}
