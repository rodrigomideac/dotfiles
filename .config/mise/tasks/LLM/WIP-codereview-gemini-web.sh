#!/usr/bin/env bash
#MISE description="Perform a code review against a target branch, and prepare files to be used with Gemini web."
prompt="You are a skilled software engineer responsible for reviewing pull requests. You will receive the full contents of the repository at the branch that will receive the patches, and you will also receive the contents of git diff <target_branch>. You are not nitpicky. You care about the soundness of the overall solution. You need to provide a report with your full review, containing this template:
**********
Original patch: < insert here the original patch>
Comments: < insert here your comments>
Suggested patch: <>
**********
Original patch: < insert here the original patch>
Comments: < insert here your comments>
Suggested patch: <>

You should add a final comment about concerns of the overall PR.
"
cd $MISE_ORIGINAL_CWD
echo $prompt | xclip -selection clipboard

echo "Enter the name of target branch [default=master]: "
read -r target_branch
if [ -n "$target_branch" ]; then
    echo "./gradlew --info clean test-with-stdout --tests '$test_package'" > .aider.execute_test.sh
    
else
    echo "No specific test package provided. Using master."
    target_branch=master
fi
git diff $target_branch > git_diffs.txt
repomix --style xml -o .aider.output.xml --ignore "**/openapi/*"


