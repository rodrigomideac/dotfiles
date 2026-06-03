return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Create a more robust CSS module navigation function
      -- opts.require_styles_access: only act when the cursor is actually on the
      -- <name> part of a `styles.<name>` expression (used by the gd override so
      -- regular identifiers fall through to the LSP definition).
      local function create_css_module_handler(opts)
        opts = opts or {}

        -- Returns the class name only when the cursor sits inside the <name>
        -- part of a `styles.<name>` expression on the current line.
        local function styles_member_under_cursor(line)
          local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- byte col, 1-based
          local init = 1
          while true do
            local s, e, name = line:find("styles%.([a-zA-Z_][a-zA-Z0-9_-]*)", init)
            if not s then
              return nil
            end
            if col >= e - #name + 1 and col <= e then
              return name
            end
            init = e + 1
          end
        end

        local function go_to_css_module()
          local current_dir = vim.fn.expand("%:p:h")
          local line = vim.api.nvim_get_current_line()

          -- Pattern 1: Handle import statements
          if line:match("import.*from.*%.module%.css") then
            local css_path = line:match('from%s+["\']([^"\']+%.module%.css)["\']')
            if css_path then
              local full_path
              if css_path:sub(1, 1) == "." then
                full_path = vim.fn.resolve(current_dir .. "/" .. css_path)
              else
                full_path = css_path
              end

              if vim.fn.filereadable(full_path) == 1 then
                vim.cmd("edit " .. full_path)
                return true
              end
            end
          end

          -- Pattern 2: cursor on a `styles.className` member access
          local class_name = styles_member_under_cursor(line)

          -- Lenient mode (<leader>gc): the user asked for CSS navigation
          -- explicitly, so fall back to the raw word under the cursor.
          if not class_name and not opts.require_styles_access then
            local cword = vim.fn.expand("<cword>")
            if cword:match("^[a-zA-Z_][a-zA-Z0-9_-]*$") then
              class_name = cword
            end
          end

          -- Look for CSS module file
          if class_name then
            local base_name = vim.fn.expand("%:t:r")
            local css_module_file = current_dir .. "/" .. base_name .. ".module.css"

            if vim.fn.filereadable(css_module_file) == 1 then
              vim.cmd("edit " .. css_module_file)
              vim.cmd("normal! gg")

              -- Try multiple search patterns
              local patterns = {
                "\\." .. class_name .. "\\>",
                "\\." .. class_name:gsub("(%u)", "-%1"):lower():gsub("^-", "") .. "\\>",
                class_name .. "\\s*{",
                class_name:gsub("(%u)", "-%1"):lower():gsub("^-", "") .. "\\s*{"
              }

              for _, pattern in ipairs(patterns) do
                if vim.fn.search(pattern, "W") > 0 then
                  break
                end
                vim.cmd("normal! gg")
              end
              return true
            end
          end

          return false
        end

        return go_to_css_module
      end
      
      -- Enhanced LSP attach with better detection
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("CSSModulesNavigation", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf
          local filetype = vim.bo[bufnr].filetype
          
          -- Only attach to TypeScript/JavaScript files
          if not (filetype == "typescript" or filetype == "typescriptreact" or filetype == "javascript" or filetype == "javascriptreact") then
            return
          end
          
          -- Check if it's a TypeScript-related LSP client
          if client and (
            client.name == "vtsls" or 
            client.name == "tsserver" or 
            client.name == "typescript-tools" or
            client.name == "typescript-language-server"
          ) then
            local css_handler = create_css_module_handler({ require_styles_access = true })
            local css_jump = create_css_module_handler()

            -- Dedicated CSS module navigation
            vim.keymap.set("n", "<leader>gc", css_jump, {
              buffer = bufnr,
              desc = "Go to CSS module",
            })

            -- Schedule the gd override to run after LazyVim's keymaps are set
            vim.defer_fn(function()
              -- Enhanced gd handler with higher priority
              vim.keymap.set("n", "gd", function()
                if not css_handler() then
                  vim.lsp.buf.definition()
                end
              end, {
                buffer = bufnr,
                desc = "Go to definition (CSS modules aware)",
                remap = false,
                silent = true,
              })
            end, 100)
          end
        end,
      })
      
      -- Additional approach: Override gd globally for TS/JS files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        group = vim.api.nvim_create_augroup("CSSModulesGlobal", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local css_handler = create_css_module_handler({ require_styles_access = true })

          -- Override gd with delay to ensure it takes precedence
          vim.defer_fn(function()
            vim.keymap.set("n", "gd", function()
              if not css_handler() then
                vim.lsp.buf.definition()
              end
            end, {
              buffer = bufnr,
              desc = "Go to definition (CSS modules aware)",
              remap = false,
              silent = true,
            })
          end, 200)
        end,
      })
    end,
  },
  
  -- Optional: Add telescope extension for CSS module search
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function(_, opts)
      -- Add custom picker for CSS modules
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      
      local function find_css_modules()
        local current_dir = vim.fn.expand("%:p:h")
        local css_files = vim.fn.glob(current_dir .. "/*.module.css", false, true)
        
        if #css_files == 0 then
          vim.notify("No CSS module files found in current directory", vim.log.levels.WARN)
          return
        end
        
        pickers.new({}, {
          prompt_title = "CSS Modules",
          finder = finders.new_table({
            results = css_files,
            entry_maker = function(entry)
              return {
                value = entry,
                display = vim.fn.fnamemodify(entry, ":t"),
                ordinal = vim.fn.fnamemodify(entry, ":t"),
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              vim.cmd("edit " .. selection.value)
            end)
            return true
          end,
        }):find()
      end
      
      -- Add keymap for CSS module picker
      vim.keymap.set("n", "<leader>fC", find_css_modules, { desc = "Find CSS Modules" })
    end,
  },
}