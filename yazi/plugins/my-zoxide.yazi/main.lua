local state = ya.sync(function(st)
	return {
		cwd = tostring(cx.active.current.cwd),
	}
end)

local function fail(s, ...)
	ya.notify({
		title = "Zoxide",
		content = string.format(s, ...),
		timeout = 5,
		level = "Error",
	})
end

local function setup(_, opts)
	opts = opts or {}

	-- 自动添加目录到 zoxide 数据库
	if opts.update_db then
		ps.sub("cd", function()
			ya.manager_emit("shell", {
				cwd = fs.cwd(),
				orphan = true,
				"zoxide add " .. ya.quote(tostring(cx.active.current.cwd)),
			})
		end)
	end
end

local function entry()
	local _permit = ya.hide()
	local st = state()

	-- 启动 zoxide 交互式查询
	local child, err = Command("zoxide")
		:args({ "query", "-i", "--exclude" }) -- -i 表示交互模式
		:arg(st.cwd)
		:stdin(Command.INHERIT)
		:stdout(Command.PIPED)
		:stderr(Command.INHERIT)
		:spawn()

	if not child then
		return fail("Failed to start `zoxide`, error: " .. err)
	end

	-- 等待结果
	local output, err = child:wait_with_output()
	if not output then
		return fail("Cannot read `zoxide` output, error: " .. err)
	elseif not output.status.success then
		-- zoxide 取消操作（如 Ctrl+C）的退出码为 1，需特殊处理
		if output.status.code == 1 then
			return -- 静默忽略
		else
			return fail("`zoxide` exited with error code %s", output.status.code)
		end
	end

	-- 处理路径
	local target = output.stdout:gsub("\n$", "")
	if target ~= "" then
		ya.manager_emit("cd", { target }) -- zoxide 只返回目录，直接跳转
	end
end

return { setup = setup, entry = entry }
