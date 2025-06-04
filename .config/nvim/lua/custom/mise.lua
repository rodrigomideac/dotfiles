vim.api.nvim_set_keymap('n', '<leader>mkf', ':lua CreateMiseTaskFilePrompt()<CR>', { noremap = true, silent = true, desc = 'Create Mise Task File' })

function CreateMiseTaskFilePrompt()
  local filename = vim.fn.input 'Enter filename for Mise task: '
  if filename == nil or filename == '' then
    print 'File creation cancelled.'
    return
  end

  local file_path = vim.fn.expand('~/.config/mise/tasks/' .. filename)
  local content = [[
#!/usr/bin/env bash
#MISE description="FILL"
prompt="You are a skilled software engineer responsible for..."
cd $MISE_ORIGINAL_CWD
echo $prompt > .aider.prompt.txt

echo "Enter a package.ClassNameTest:"
read -r test_package
if [ -n "$test_package" ]; then
    echo "./gradlew --info clean test-with-stdout --tests '$test_package'" > .aider.execute_test.sh
    
else
    echo "No specific test package provided. Using what is set previously:"
    cat .aider.execute_test.sh
fi
chmod +x .aider.execute_test.sh  

aider --model gemini/gemini-2.5-flash-preview-05-20 --read .aider.prompt.txt --test-cmd "sh .aider.execute_test.sh" --auto-test --yes-always

]]

  local file = io.open(file_path, 'w')
  if file then
    file:write(content)
    io.close(file)
    vim.fn.system('chmod +x ' .. file_path)
    vim.cmd('edit ' .. file_path)
  else
    print('Error: Could not create file at ' .. file_path)
  end
end
