import { homedir } from "node:os"
import { basename, join } from "node:path"

function addUnique(values, value) {
  if (!values.includes(value)) values.push(value)
}

function projectMemoryName(input) {
  const name =
    process.env.OPENCODE_MEMORY_PROJECT ||
    input.project?.name ||
    basename(input.worktree || input.directory || process.cwd())

  return (
    String(name)
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9._-]+/g, "-")
      .replace(/^-+|-+$/g, "") || "default"
  )
}

export const ProjectMemoryPlugin = async (input) => {
  const memoryRoot = process.env.OPENCODE_MEMORY_DIR || join(homedir(), ".opencode")
  const projectName = projectMemoryName(input)

  return {
    config: async (config) => {
      const instructions = Array.isArray(config.instructions) ? config.instructions : []

      config.instructions = instructions
      addUnique(instructions, join(memoryRoot, "memory", "*.md"))
      addUnique(instructions, join(memoryRoot, projectName, "memory", "*.md"))
    },
  }
}

export default ProjectMemoryPlugin
