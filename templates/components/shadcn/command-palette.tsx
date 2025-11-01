"use client"

import { useEffect, useState, useCallback } from "react"
import { Command } from "cmdk"
import { Search, FileText, Code, Book, Settings } from "lucide-react"
import { Dialog, DialogContent } from "@/components/ui/dialog"
import { useRouter } from "next/navigation"

interface CommandItem {
  id: string
  title: string
  description?: string
  category: string
  icon: React.ReactNode
  action: () => void
}

export function CommandPalette() {
  const [open, setOpen] = useState(false)
  const [search, setSearch] = useState("")
  const router = useRouter()

  // Toggle command palette with Cmd+K or Ctrl+K
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setOpen((open) => !open)
      }
    }

    document.addEventListener("keydown", down)
    return () => document.removeEventListener("keydown", down)
  }, [])

  // Sample commands - replace with your actual navigation structure
  const commands: CommandItem[] = [
    {
      id: "home",
      title: "Home",
      description: "Go to homepage",
      category: "Navigation",
      icon: <FileText className="h-4 w-4" />,
      action: () => router.push("/"),
    },
    {
      id: "docs",
      title: "Documentation",
      description: "Browse documentation",
      category: "Navigation",
      icon: <Book className="h-4 w-4" />,
      action: () => router.push("/docs"),
    },
    {
      id: "examples",
      title: "Examples",
      description: "View code examples",
      category: "Navigation",
      icon: <Code className="h-4 w-4" />,
      action: () => router.push("/examples"),
    },
    {
      id: "settings",
      title: "Settings",
      description: "Configure preferences",
      category: "Settings",
      icon: <Settings className="h-4 w-4" />,
      action: () => router.push("/settings"),
    },
  ]

  const runCommand = useCallback((command: CommandItem) => {
    setOpen(false)
    command.action()
  }, [])

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="overflow-hidden p-0">
        <Command className="[&_[cmdk-group-heading]]:px-2 [&_[cmdk-group-heading]]:font-medium [&_[cmdk-group-heading]]:text-muted-foreground [&_[cmdk-group]:not([hidden])_~[cmdk-group]]:pt-0 [&_[cmdk-group]]:px-2 [&_[cmdk-input-wrapper]_svg]:h-5 [&_[cmdk-input-wrapper]_svg]:w-5 [&_[cmdk-input]]:h-12 [&_[cmdk-item]]:px-2 [&_[cmdk-item]]:py-3 [&_[cmdk-item]_svg]:h-5 [&_[cmdk-item]_svg]:w-5">
          <div className="flex items-center border-b px-3">
            <Search className="mr-2 h-4 w-4 shrink-0 opacity-50" />
            <Command.Input
              placeholder="Type a command or search..."
              value={search}
              onValueChange={setSearch}
              className="flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50"
            />
          </div>
          <Command.List className="max-h-[300px] overflow-y-auto overflow-x-hidden">
            <Command.Empty className="py-6 text-center text-sm">
              No results found.
            </Command.Empty>
            {Object.entries(
              commands.reduce((groups, command) => {
                if (!groups[command.category]) {
                  groups[command.category] = []
                }
                groups[command.category].push(command)
                return groups
              }, {} as Record<string, CommandItem[]>)
            ).map(([category, items]) => (
              <Command.Group key={category} heading={category}>
                {items.map((command) => (
                  <Command.Item
                    key={command.id}
                    value={command.title}
                    onSelect={() => runCommand(command)}
                    className="cursor-pointer"
                  >
                    <div className="flex items-center gap-2">
                      {command.icon}
                      <div className="flex flex-col">
                        <span>{command.title}</span>
                        {command.description && (
                          <span className="text-xs text-muted-foreground">
                            {command.description}
                          </span>
                        )}
                      </div>
                    </div>
                  </Command.Item>
                ))}
              </Command.Group>
            ))}
          </Command.List>
        </Command>
      </DialogContent>
    </Dialog>
  )
}

// Usage: Add to your layout
// <CommandPalette />
// Users can press Cmd+K (Mac) or Ctrl+K (Windows/Linux) to open
