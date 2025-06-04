#!/usr/bin/env bash
#MISE description="Starts Aider to implement a spec.md."
prompt="You are a very rigorous developer that follows instructions. You are not creative. You just know how to read a spec file and perform the changes. You should perform eveything that is in spec.md andvalidate with make test, if this Makefile target exists."

# repomix --style xml -o output.xml && llm chat -m   gemini-2.5-flash-preview-05-20 -s "$prompt" -a output.xml
cd $MISE_ORIGINAL_CWD && aider --chat-mode code --model gemini/gemini-2.5-flash-preview-05-20 --read spec.md
