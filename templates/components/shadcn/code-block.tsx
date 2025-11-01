"use client"

import { useState } from "react"
import { Check, Copy } from "lucide-react"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface CodeBlockProps {
  code: string
  language: string
  filename?: string
  showLineNumbers?: boolean
  highlightLines?: number[]
  className?: string
}

export function CodeBlock({
  code,
  language,
  filename,
  showLineNumbers = false,
  highlightLines = [],
  className,
}: CodeBlockProps) {
  const [isCopied, setIsCopied] = useState(false)

  const copyToClipboard = async () => {
    await navigator.clipboard.writeText(code)
    setIsCopied(true)
    setTimeout(() => setIsCopied(false), 2000)
  }

  const lines = code.split("\n")

  return (
    <div className={cn("group relative rounded-lg border bg-zinc-950", className)}>
      {/* Header */}
      {filename && (
        <div className="flex items-center justify-between border-b border-zinc-800 px-4 py-2">
          <span className="text-sm text-zinc-400">{filename}</span>
          <span className="text-xs text-zinc-500 uppercase">{language}</span>
        </div>
      )}

      {/* Code Container */}
      <div className="relative">
        {/* Copy Button */}
        <Button
          size="icon"
          variant="ghost"
          className="absolute right-4 top-4 opacity-0 transition-opacity group-hover:opacity-100"
          onClick={copyToClipboard}
        >
          {isCopied ? (
            <Check className="h-4 w-4" />
          ) : (
            <Copy className="h-4 w-4" />
          )}
        </Button>

        {/* Code */}
        <pre className="overflow-x-auto p-4">
          <code className={`language-${language}`}>
            {showLineNumbers ? (
              <div className="table">
                {lines.map((line, index) => (
                  <div
                    key={index}
                    className={cn(
                      "table-row",
                      highlightLines.includes(index + 1) &&
                        "bg-zinc-800/50"
                    )}
                  >
                    <span className="table-cell select-none pr-4 text-right text-zinc-500">
                      {index + 1}
                    </span>
                    <span className="table-cell">{line}</span>
                  </div>
                ))}
              </div>
            ) : (
              code
            )}
          </code>
        </pre>
      </div>
    </div>
  )
}

// Usage Example:
// <CodeBlock 
//   code={`function hello() {\n  console.log("Hello World")\n}`}
//   language="javascript"
//   filename="example.js"
//   showLineNumbers
//   highlightLines={[2]}
// />
