
# workflow

Document and share your project workflows.

When working in teams, each developer commonly has a number of tasks they
perform while working on a project. For example, a developer might execute
a set of commands to deploy the project, or clear the cache on a development
machine.

These workflows are usually thought up by one developer, and then never
written down or shared anywhere. Even though this is usually quite valuable
knowledge about working with the project!

Workflow is a simple template for a command line tool in which all of these
different workflows may be stored and shared among the team.


## Installation

Copy the top-level `wf` file to your project directory. Then copy the
`workflow` directory somewhere in your project. If it's not in the project
root you'll need to adjust the path in `wf`.


## Usage

The first time you try to run workflow you'll run into the following error:

> Couldn't find local configuration. Please create and modify
> '.env' or run the 'install' command.

This means that you haven't configured workflow yet. Projects will usually
have machine-dependent configuration, including sensitive information like
passwords, or just for personal preferences (e.g. your preferred editor).
There is a template available at `.env.example` which you
can copy and customize (or run `./wf install`).

### Adding new commands

By default workflow does nothing, it's just a template. You can add your
project-specific commands in `workflow/modules/project.sh`.
