import Command
import Institute_Application
import Institute_Workspace_Application
import Institute_Model

await Command.main(Institute.Application.CLI.self, initial: .sync(.init()))
