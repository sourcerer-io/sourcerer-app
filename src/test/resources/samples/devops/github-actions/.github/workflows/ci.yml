name: Greet Everybody
# This workflow is triggered on pushes to the repository.
on: [push]

jobs:
  build:
    # Job name is Greeting
    name: Greeting
    # This job runs on Linux
    runs-on: ubuntu-latest
    steps:
    # This step uses the hello-world-action stored in this workflow's repository.
    - uses: ./hello-world-action
      with:
        who-to-greet: 'Octocat'
      id: hello
    # This step prints the time.
    - run: echo "The time was ${{ steps.hello.outputs.time }}"
