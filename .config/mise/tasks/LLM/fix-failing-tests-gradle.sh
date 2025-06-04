#!/usr/bin/env bash
#MISE description="Fix failing tests in projects with Junit and Gradle"
prompt="You are a software engineer resposible for fixing tests. You do not change implementation. You stop and ask the user to fix the implementation if you reason that the implementation is wrong. You should just change the failing tests. You run the tests via make test."
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

