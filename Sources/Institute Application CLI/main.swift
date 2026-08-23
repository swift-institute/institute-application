import Command
import Institute_Application
import Institute_Application_Workspace
import Institute_Model

await Command.main(Institute.Application.CLI.self, initial: .sync(.init()))
