return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Create a more robust CSS module navigation function
      local function create_css_module_handler()
        local function go_to_css_module()
          local current_word = vim.fn.expand("<cword>")
          local current_file = vim.fn.expand("%:p")
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
          
          -- Pattern 2: Handle CSS class usage (e.g., styles.className)
          local styles_usage = line:match("styles%.([a-zA-Z_][a-zA-Z0-9_-]*)")
          if styles_usage then
            current_word = styles_usage
          end
          
          -- Pattern 3: Handle className={styles.className}
          local classname_usage = line:match("styles%.([a-zA-Z_][a-zA-Z0-9_-]*)")
          if classname_usage then
            current_word = classname_usage
          end
          
          -- Look for CSS module file
          if current_word and current_word:match("^[a-zA-Z_][a-zA-Z0-9_-]*$") then
            local base_name = vim.fn.expand("%:t:r")
            local css_module_file = current_dir .. "/" .. base_name .. ".module.css"
            
            if vim.fn.filereadable(css_module_file) == 1 then
              vim.cmd("edit " .. css_module_file)
              vim.cmd("normal! gg")
              
              -- Try multiple search patterns
              local patterns = {
                "\\." .. current_word .. "\\>",
                "\\." .. current_word:gsub("(%u)", "-%1"):lower():gsub("^-", "") .. "\\>",
                current_word .. "\\s*{",
                current_word:gsub("(%u)", "-%1"):lower():gsub("^-", "") .. "\\s*{"
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
            local css_handler = create_css_module_handler()
            
            -- Dedicated CSS module navigation
            vim.keymap.set("n", "<leader>gc", css_handler, {
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
          local css_handler = create_css_module_handler()
          
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