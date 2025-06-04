#!/usr/bin/env bash
#MISE description="Generates readme from the full repository"
cd $MISE_ORIGINAL_CWD 

prompt="You are a senior software engineer. Look at the whole code base and the existing readme. Propose a full version of a readme that contemplates the essential funcionality of the codebase." 

echo $prompt > .aider.prompt.txt

repomix --style markdown \
	--ignore "**/resources/*,**/openapi/*" \
	-o .aider.codebase.txt

(cat .aider.prompt.txt; echo "------\nThis is the whole codebase: "; cat .aider.codebase.txt) > prompt_and_codebase.txt

echo "There is a prompt_and_codebase.txt file to be used with web interface if needed."

aider 	--message-file .aider.prompt.txt \
	--model gemini/gemini-2.5-flash-preview-05-20 \
	--read .aider.codebase.txt
