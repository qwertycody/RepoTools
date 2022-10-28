# RepoTools:
- This is a starting point template to setup development automation using bash logic if your checkout process is relatively complicated

# Warning:
- These tools are provided "as is"
- Review the scripts before you run them to make sure you agree with the changes that will be made on your computer

# Contributing:
- Please feel free to contribute back if this helped so we can all have an automated framework for setting up and working on the application locally 

# To Automate Checkout:
- Create a file in this root directory and name it args_private.sh 
- Populate it with the following lines:
    - #!/bin/bash
    - REPOSITORY_USERNAME="your_git_username"
    - REPOSITORY_PASSWORD="ghp_your_github_token"

# To make sure your args aren't overwritten if you pull down the latest repotools:
- Copy your desired variables into args_private.sh
- These args override anything that is inherited in the args.sh aka different checkout branch and checkout urls