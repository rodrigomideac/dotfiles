#!/usr/bin/env bash
#MISE description="Starts a chat to polish an idea."
cd $MISE_ORIGINAL_CWD 

prompt=" You are a skillfull master software engineer. I will propose a change to the codebase that I have sent to you attached, and you need to reason about how to implement it. Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question should build on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer. Let’s do this iteratively and dig into every relevant detail. Remember, only one question at a time. When the user says that you can compile now, you will compile your findings into a comprehensive, developer-ready specification, including all relevant requirements, architecture choices, data handling details, error handling strategies, and a testing plan so a developer can immediately begin implementation. You will begin the chat aknowledging what the codebase is about, in one sentence. Then you will ask the user what he wants to implement. If no file is provided, ask the user to try again with a codebase file."

prompt_wrap_up="Now that we’ve wrapped up the brainstorming process, can you compile our findings into a comprehensive, developer-ready specification? Include all relevant requirements, architecture choices, data handling details, error handling strategies, and a testing plan so a developer can immediately begin implementation."

echo $prompt > .aider.prompt.txt
echo $prompt_wrap_up > .aider.prompt_wrap_up.txt

repomix --style markdown -o .aider.codebase.txt

(cat .aider.prompt.txt; echo "------\nThis is the whole codebase: "; cat .aider.codebase.txt) > prompt_and_codebase.txt

echo "There is a prompt_and_codebase.txt file to be used with web interface if needed."

aider 	--chat-mode ask \
	--model gemini/gemini-2.5-flash-preview-05-20 \
	--read .aider.prompt.txt \
	--read .aider.prompt_wrap_up.txt
