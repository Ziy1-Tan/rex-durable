-- More end-to-end helpers for test/e2e.sh, on the throwaway Rex server only:
--   action=sub bin=DIR dir=DIR   a session with an fx chat that runs a subagent
--   action=close label=NAME      close every tab of one session, as if killed
--   action=claudes bin=DIR dir=DIR old=ID new=ID
--                                a session "pair" with three Claude chats in one
--                                folder: two new ones, and one that switched from
--                                session old to session new

local a = rex.args
local function q(word) return "'" .. word:gsub("'", "'\\''") .. "'" end

if a.action == "sub" then
  assert(rex.call("session.create", { label = "sub", initial_windows = { { layout = { block = {
    flavor = "com.superlogical.terminal.shell",
    options = { cwd = a.dir, initial_input = q(a.bin .. "/fx") .. " --resume FXP --child SUBC1\n" },
  } } } } }))
elseif a.action == "claudes" then
  local function tab(command)
    return { layout = { block = { flavor = "com.superlogical.terminal.shell",
      options = { cwd = a.dir, initial_input = command .. "\n" } } } }
  end
  local claude = q(a.bin .. "/claude") .. " --write-pid-file"
  assert(rex.call("session.create", { label = "pair", initial_windows = {
    tab(claude),
    tab(claude),
    tab(claude .. " --resume " .. a.old .. " --switch-to " .. a.new),
  } }))
elseif a.action == "close" then
  for _, s in ipairs(rex.call("session.list").sessions or {}) do
    if s.label == a.label then
      rex.session.attach{ session_id = s.session_id }
      local view = rex.session.view{ session_id = s.session_id }
      for _, w in ipairs(view.windows or {}) do
        rex.call("session.close_window", { session_id = s.session_id, window_id = w.window_id })
      end
    end
  end
end
return "ok"
