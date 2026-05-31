local api = vim.api

local function setup_buffer_commands(bufnr, client_id, effective_bufnr)
    effective_bufnr = effective_bufnr or bufnr

    api.nvim_buf_create_user_command(bufnr, 'SqlsExecuteQuery', function(args)
        require('sqls.commands').exec(
            client_id,
            'executeQuery',
            args.smods,
            args.range ~= 0,
            nil,
            args.line1,
            args.line2,
            effective_bufnr
        )
    end, { range = true })
    api.nvim_buf_create_user_command(bufnr, 'SqlsExecuteQueryVertical', function(args)
        require('sqls.commands').exec(
            client_id,
            'executeQuery',
            args.smods,
            args.range ~= 0,
            '-show-vertical',
            args.line1,
            args.line2,
            effective_bufnr
        )
    end, { range = true })
    api.nvim_buf_create_user_command(bufnr, 'SqlsShowDatabases', function(args)
        require('sqls.commands').exec(client_id, 'showDatabases', args.smods, false, nil, nil, nil, effective_bufnr)
    end, {})
    api.nvim_buf_create_user_command(bufnr, 'SqlsShowSchemas', function(args)
        require('sqls.commands').exec(client_id, 'showSchemas', args.smods, false, nil, nil, nil, effective_bufnr)
    end, {})
    api.nvim_buf_create_user_command(bufnr, 'SqlsShowConnections', function(args)
        require('sqls.commands').exec(client_id, 'showConnections', args.smods, false, nil, nil, nil, effective_bufnr)
    end, {})
    api.nvim_buf_create_user_command(bufnr, 'SqlsShowTables', function(args)
        require('sqls.commands').exec(client_id, 'showTables', args.smods, false, nil, nil, nil, effective_bufnr)
    end, {})
    -- Not yet supported by the language server:
    -- api.nvim_buf_create_user_command(bufnr, 'SqlsDescribeTable', function(args)
    --     require('sqls.commands').exec(client_id, 'describeTable', args.smods, false, nil, nil, nil, effective_bufnr)
    -- end, {})
    api.nvim_buf_create_user_command(bufnr, 'SqlsSwitchDatabase', function(args)
        require('sqls.commands').switch_database(client_id, args.args ~= '' and args.args or nil)
    end, { nargs = '?' })
    api.nvim_buf_create_user_command(bufnr, 'SqlsSwitchConnection', function(args)
        require('sqls.commands').switch_connection(client_id, args.args ~= '' and args.args or nil)
    end, { nargs = '?' })

    api.nvim_buf_set_keymap(
        bufnr,
        'n',
        '<Plug>(sqls-execute-query)',
        "<Cmd>let &opfunc='{type -> sqls_nvim#query(type, " .. client_id .. ', ' .. effective_bufnr .. ")}'<CR>g@",
        { silent = true }
    )
    api.nvim_buf_set_keymap(
        bufnr,
        'x',
        '<Plug>(sqls-execute-query)',
        "<Cmd>let &opfunc='{type -> sqls_nvim#query(type, " .. client_id .. ', ' .. effective_bufnr .. ")}'<CR>g@",
        { silent = true }
    )
    api.nvim_buf_set_keymap(
        bufnr,
        'n',
        '<Plug>(sqls-execute-query-vertical)',
        "<Cmd>let &opfunc='{type -> sqls_nvim#query_vertical(type, " .. client_id .. ', ' .. effective_bufnr .. ")}'<CR>g@",
        { silent = true }
    )
    api.nvim_buf_set_keymap(
        bufnr,
        'x',
        '<Plug>(sqls-execute-query-vertical)',
        "<Cmd>let &opfunc='{type -> sqls_nvim#query_vertical(type, " .. client_id .. ', ' .. effective_bufnr .. ")}'<CR>g@",
        { silent = true }
    )
end

return {
    cmd = { 'sqls' },
    filetypes = { 'sql', 'mysql' },
    commands = {
        executeQuery = function(_, client)
            require('sqls.commands').exec(client.client_id, 'executeQuery')
        end,
        showDatabases = function(_, client)
            require('sqls.commands').exec(client.client_id, 'showDatabases')
        end,
        showSchemas = function(_, client)
            require('sqls.commands').exec(client.client_id, 'showSchemas')
        end,
        showConnections = function(_, client)
            require('sqls.commands').exec(client.client_id, 'showConnections')
        end,
        showTables = function(_, client)
            require('sqls.commands').exec(client.client_id, 'showTables')
        end,
        describeTable = function(_, client)
            require('sqls.commands').exec(client.client_id, 'describeTable')
        end,
        switchConnections = function(_, client)
            require('sqls.commands').switch_connection(client.client_id)
        end,
        switchDatabase = function(_, client)
            require('sqls.commands').switch_database(client.client_id)
        end,
    },
    on_attach = function(client, bufnr)
        local client_id = client.id
        setup_buffer_commands(bufnr, client_id, bufnr)

        -- otter.nvim integration: if this buffer is an otter buffer,
        -- also create commands on the parent (main) buffer so they are
        -- accessible from e.g. a Python file containing embedded SQL.
        local ok, keeper = pcall(require, 'otter.keeper')
        if ok then
            for main_nr, raft in pairs(keeper.rafts) do
                for _, otter_nr in pairs(raft.buffers) do
                    if otter_nr == bufnr then
                        setup_buffer_commands(main_nr, client_id, bufnr)
                    end
                end
            end
        end
    end,
}
